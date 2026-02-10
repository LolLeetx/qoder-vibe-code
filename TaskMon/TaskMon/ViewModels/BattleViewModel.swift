import Foundation
import Combine
import SwiftUI

enum BattleMode {
    case local
    case online
}

class BattleViewModel: ObservableObject {
    @Published var currentBattle: Battle?
    @Published var selectedTeam: [Creature] = []
    @Published var battleMode: BattleMode = .local
    @Published var battlePhase: BattlePhase = .setup
    @Published var isPlayerTurn: Bool = true
    @Published var lastLogMessages: [String] = []
    @Published var showBattleResult: Bool = false
    @Published var playerWon: Bool = false
    @Published var isMatchmaking: Bool = false
    @Published var matchmakingSeconds: Int = 0
    @Published var shakePlayer1: Bool = false
    @Published var shakePlayer2: Bool = false
    @Published var isOnlineBattle: Bool = false
    @Published var waitingForOpponent: Bool = false

    private var matchmakingTimer: Timer?
    private var queueObserverHandle: Any?
    private var battleObserverHandle: Any?
    private var matchProcessed = false
    private var amPlayer1 = true
    private var onlineBattleId: String?
    private var onlineOpponentId: String?
    private var lastAppliedLogCount: Int = 0
    private var isResolvingTurn = false

    private let battleService = ServiceContainer.shared.realtimeBattle
    private let authService = ServiceContainer.shared.auth

    enum BattlePhase {
        case setup
        case fighting
        case finished
    }

    var playerId: String {
        authService.currentUserId ?? "player"
    }
    private let aiId = "AI Trainer"

    // MARK: - Team Selection

    func toggleCreatureSelection(_ creature: Creature) {
        if let idx = selectedTeam.firstIndex(where: { $0.id == creature.id }) {
            selectedTeam.remove(at: idx)
        } else if selectedTeam.count < GameConstants.maxTeamSize {
            selectedTeam.append(creature)
        }
    }

    func isSelected(_ creature: Creature) -> Bool {
        selectedTeam.contains(where: { $0.id == creature.id })
    }

    // MARK: - Local Battle

    func startLocalBattle() {
        guard !selectedTeam.isEmpty else { return }

        var team = selectedTeam
        for i in team.indices { team[i].heal() }

        let aiTeam = CreatureGenerator.generateMatchedAITeam(playerTeam: team)

        var battle = Battle(player1Id: playerId, player2Id: aiId, player1Team: team, player2Team: aiTeam)
        battle.addLog("You sent out \(team[0].name)!")
        battle.addLog("\(aiId) sent out \(aiTeam[0].name)!")

        currentBattle = battle
        battlePhase = .fighting
        isPlayerTurn = true
        lastLogMessages = battle.battleLog
    }

    // MARK: - Player Actions

    func playerSelectMove(_ moveIndex: Int) {
        guard let battle = currentBattle, !battle.isOver, isPlayerTurn else { return }

        if isOnlineBattle {
            submitOnlineAction(.useMove(moveIndex))
        } else {
            resolveLocalTurn(playerAction: .useMove(moveIndex))
        }
    }

    func playerSwitchCreature(_ index: Int) {
        guard let battle = currentBattle, !battle.isOver, isPlayerTurn else { return }

        if isOnlineBattle {
            submitOnlineAction(.switchCreature(index))
        } else {
            resolveLocalTurn(playerAction: .switchCreature(index))
        }
    }

    func forfeit() {
        guard let battle = currentBattle else { return }

        if isOnlineBattle {
            submitOnlineAction(.forfeit)
        } else {
            var mutable = battle
            mutable.winnerId = aiId
            mutable.status = .finished
            mutable.addLog("You forfeited!")
            currentBattle = mutable
            battlePhase = .finished
            playerWon = false
            showBattleResult = true
        }
    }

    // MARK: - Local Turn Resolution

    private func resolveLocalTurn(playerAction: BattleAction) {
        guard var battle = currentBattle else { return }

        isPlayerTurn = false

        let aiAction = BattleEngine.selectAIAction(battle: battle)
        let oldLog = battle.battleLog.count
        BattleEngine.resolveTurn(battle: &battle, player1Action: playerAction, player2Action: aiAction)

        let newMessages = Array(battle.battleLog.dropFirst(oldLog))
        currentBattle = battle

        animateLogMessages(newMessages) {
            if battle.isOver {
                self.battlePhase = .finished
                self.playerWon = battle.winnerId == self.playerId
                self.showBattleResult = true
            } else {
                self.isPlayerTurn = true
            }
        }
    }

    // MARK: - Online Action Submission

    private func submitOnlineAction(_ action: BattleAction) {
        guard let battleId = onlineBattleId else { return }

        isPlayerTurn = false
        waitingForOpponent = true

        Task {
            try? await battleService.setPlayerAction(
                battleId: battleId,
                isPlayer1: amPlayer1,
                action: action
            )
        }
    }

    // MARK: - Online Matchmaking

    func startMatchmaking() {
        guard !selectedTeam.isEmpty else { return }
        isMatchmaking = true
        matchmakingSeconds = 0

        matchmakingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.matchmakingSeconds += 1
            }
        }

        Task { @MainActor in
            do {
                var pid = self.playerId
                if !authService.isAuthenticated {
                    pid = try await authService.signInAnonymously()
                }

                var team = selectedTeam
                for i in team.indices { team[i].heal() }

                // Clean up any stale queue entry AND stale battle from a previous session
                try? await battleService.leaveQueue(playerId: pid)

                // Join queue FIRST so our entry is written before we start observing
                try await battleService.joinQueue(playerId: pid, team: team)
                print("[Matchmaking] Joined queue as \(pid) with team: \(team.map { $0.name })")

                // Now observe — our fresh entry is already in place
                self.queueObserverHandle = battleService.observeQueue { [weak self] player1Id, player2Id in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        self.handleMatchFound(player1Id: player1Id, player2Id: player2Id)
                    }
                }
            } catch {
                print("Matchmaking error: \(error)")
                self.cancelMatchmaking()
            }
        }
    }

    func cancelMatchmaking() {
        isMatchmaking = false
        matchmakingSeconds = 0
        matchProcessed = false
        matchmakingTimer?.invalidate()
        matchmakingTimer = nil

        if let handle = queueObserverHandle {
            battleService.removeObserver(handle)
            queueObserverHandle = nil
        }

        let pid = playerId
        Task {
            try? await battleService.leaveQueue(playerId: pid)
        }
    }

    // MARK: - Match Found

    private func handleMatchFound(player1Id: String, player2Id: String) {
        let pid = playerId
        guard player1Id == pid || player2Id == pid else { return }
        guard isMatchmaking, !matchProcessed else { return }
        matchProcessed = true

        matchmakingTimer?.invalidate()
        matchmakingTimer = nil

        if let handle = queueObserverHandle {
            battleService.removeObserver(handle)
            queueObserverHandle = nil
        }

        isMatchmaking = false
        isOnlineBattle = true

        let opponentId = (player1Id == pid) ? player2Id : player1Id
        onlineOpponentId = opponentId

        // Host = alphabetically lower ID
        let sortedIds = [pid, opponentId].sorted()
        amPlayer1 = (sortedIds[0] == pid)
        onlineBattleId = "\(sortedIds[0])_vs_\(sortedIds[1])"

        Task { @MainActor in
            if amPlayer1 {
                // Host: fetch opponent's team, create battle, push to Firebase
                var myTeam = selectedTeam
                for i in myTeam.indices { myTeam[i].heal() }

                var oppTeam: [Creature]
                do {
                    if let fetched = try await battleService.fetchQueueEntry(playerId: opponentId) {
                        oppTeam = fetched
                        for i in oppTeam.indices { oppTeam[i].heal() }
                        print("[Match] Fetched opponent team: \(oppTeam.map { $0.name })")
                    } else {
                        print("[Match] Opponent queue entry was nil, using AI team")
                        oppTeam = CreatureGenerator.generateMatchedAITeam(playerTeam: myTeam)
                    }
                } catch {
                    print("[Match] Failed to decode opponent team: \(error)")
                    oppTeam = CreatureGenerator.generateMatchedAITeam(playerTeam: myTeam)
                }

                // Clean up queue AFTER fetching
                try? await battleService.leaveQueue(playerId: pid)
                try? await battleService.leaveQueue(playerId: opponentId)

                var battle = Battle(
                    player1Id: sortedIds[0],
                    player2Id: sortedIds[1],
                    player1Team: myTeam,
                    player2Team: oppTeam,
                    id: onlineBattleId!
                )
                battle.addLog("Match found!")
                battle.addLog("\(sortedIds[0]) sent out \(myTeam[0].name)!")
                battle.addLog("\(sortedIds[1]) sent out \(oppTeam[0].name)!")

                // Set battle state immediately from in-memory data (avoids Firebase roundtrip mangling)
                currentBattle = battle
                battlePhase = .fighting
                isPlayerTurn = true
                lastLogMessages = friendlyLog(battle.battleLog)
                lastAppliedLogCount = battle.battleLog.count
                print("[Match] Host battle set directly: p1=\(myTeam.map{$0.name}) p2=\(oppTeam.map{$0.name})")

                try? await battleService.createBattle(battle)
            } else {
                // Non-host: host will clean up both queue entries
            }

            // Both: start observing the shared battle
            startObservingOnlineBattle()
        }
    }

    // MARK: - Online Battle Observation

    private func startObservingOnlineBattle() {
        guard let battleId = onlineBattleId else { return }

        battleObserverHandle = battleService.observeBattle(battleId: battleId) { [weak self] battle in
            guard let self else { return }
            DispatchQueue.main.async {
                self.handleBattleUpdate(battle)
            }
        }
    }

    private func handleBattleUpdate(_ remoteBattle: Battle) {
        // Swap perspective so player1 = "us" in local display
        var displayBattle = amPlayer1 ? remoteBattle : swapPerspective(remoteBattle)

        // Host: update opponent team from non-host's team confirmation
        // This fixes race conditions where stale queue data was fetched
        if amPlayer1, let teamJSON = remoteBattle.player2TeamJSON,
           let teamData = teamJSON.data(using: .utf8),
           let confirmedTeam = try? JSONDecoder().decode([Creature].self, from: teamData) {
            if var local = currentBattle, local.player2TeamJSON != teamJSON {
                let currentNames = local.player2Team.map { $0.name }
                let confirmedNames = confirmedTeam.map { $0.name }
                if currentNames != confirmedNames {
                    print("[Match] Host updating opponent team from confirmation: \(confirmedNames)")
                }
                var healedTeam = confirmedTeam
                for i in healedTeam.indices { healedTeam[i].heal() }
                local.player2Team = healedTeam
                local.player2TeamJSON = teamJSON
                currentBattle = local
                displayBattle.player2Team = healedTeam
            }
        }

        // Initial battle load — transition to fighting
        if battlePhase != .fighting && battlePhase != .finished && remoteBattle.status == .active {
            // For non-host: replace our team with local selectedTeam to avoid Firebase mangling
            if !amPlayer1 {
                var myTeam = selectedTeam
                for i in myTeam.indices { myTeam[i].heal() }
                displayBattle.player1Team = myTeam
                print("[Match] Non-host using local team: \(myTeam.map{$0.name})")
                print("[Match] Non-host opponent team: \(displayBattle.player2Team.map{$0.name})")

                // Confirm our actual team to the host (prevents stale queue data issues)
                if let battleId = onlineBattleId {
                    if let teamData = try? JSONEncoder().encode(myTeam),
                       let teamJSON = String(data: teamData, encoding: .utf8) {
                        Task {
                            try? await self.battleService.confirmPlayerTeam(battleId: battleId, isPlayer1: false, teamJSON: teamJSON)
                        }
                    }
                }
            }
            currentBattle = displayBattle
            battlePhase = .fighting
            isPlayerTurn = true
            waitingForOpponent = false
            lastLogMessages = friendlyLog(displayBattle.battleLog)
            lastAppliedLogCount = displayBattle.battleLog.count
            return
        }

        // Host: check if both actions are submitted → resolve turn
        if amPlayer1 && !isResolvingTurn {
            let p1 = remoteBattle.player1Action
            let p2 = remoteBattle.player2Action
            let hasForfeit = p1?.type == .forfeit || p2?.type == .forfeit
            let bothReady = p1 != nil && p2 != nil

            if hasForfeit || bothReady {
                isResolvingTurn = true
                // Use LOCAL currentBattle (correct creature data) instead of remoteBattle
                guard var mutable = currentBattle else {
                    isResolvingTurn = false
                    return
                }
                let action1 = p1 ?? .useMove(0)
                let action2 = p2 ?? .useMove(0)
                mutable.player1Action = nil
                mutable.player2Action = nil

                BattleEngine.resolveTurn(battle: &mutable, player1Action: action1, player2Action: action2)
                currentBattle = mutable

                Task {
                    try? await battleService.createBattle(mutable)
                    await MainActor.run {
                        self.isResolvingTurn = false
                    }
                }
                return
            }
        }

        // Apply state updates (new log messages from resolved turn)
        let newLogCount = displayBattle.battleLog.count
        if newLogCount > lastAppliedLogCount {
            let newMessages = friendlyLog(Array(displayBattle.battleLog.dropFirst(lastAppliedLogCount)))
            lastAppliedLogCount = newLogCount

            // Merge remote changes into local battle to preserve correct creature data
            if var local = currentBattle {
                // Update HP and active index from remote (these change during battle)
                for i in local.player1Team.indices {
                    if i < displayBattle.player1Team.indices.upperBound {
                        local.player1Team[i].stats.hp = displayBattle.player1Team[i].stats.hp
                    }
                }
                for i in local.player2Team.indices {
                    if i < displayBattle.player2Team.indices.upperBound {
                        local.player2Team[i].stats.hp = displayBattle.player2Team[i].stats.hp
                    }
                }
                local.player1ActiveIndex = displayBattle.player1ActiveIndex
                local.player2ActiveIndex = displayBattle.player2ActiveIndex
                local.battleLog = displayBattle.battleLog
                local.status = displayBattle.status
                local.winnerId = displayBattle.winnerId
                local.currentTurn = displayBattle.currentTurn
                local.player1Action = nil
                local.player2Action = nil
                currentBattle = local
            } else {
                currentBattle = displayBattle
            }

            animateLogMessages(newMessages) {
                if displayBattle.isOver {
                    self.battlePhase = .finished
                    self.playerWon = remoteBattle.winnerId == self.playerId
                    self.showBattleResult = true
                    self.waitingForOpponent = false
                } else {
                    self.isPlayerTurn = true
                    self.waitingForOpponent = false
                }
            }
        }
    }

    // MARK: - Perspective Helpers

    private func swapPerspective(_ battle: Battle) -> Battle {
        var swapped = battle
        swapped.player1Id = battle.player2Id
        swapped.player2Id = battle.player1Id
        swapped.player1Team = battle.player2Team
        swapped.player2Team = battle.player1Team
        swapped.player1ActiveIndex = battle.player2ActiveIndex
        swapped.player2ActiveIndex = battle.player1ActiveIndex
        swapped.player1Action = battle.player2Action
        swapped.player2Action = battle.player1Action
        return swapped
    }

    private func friendlyLog(_ messages: [String]) -> [String] {
        guard isOnlineBattle else { return messages }
        let myId = playerId
        guard let opId = onlineOpponentId else { return messages }
        return messages.map { msg in
            var m = msg
            m = m.replacingOccurrences(of: opId, with: "Opponent")
            m = m.replacingOccurrences(of: myId, with: "You")
            return m
        }
    }

    // MARK: - Reset

    func resetBattle() {
        if let handle = battleObserverHandle {
            battleService.removeObserver(handle)
            battleObserverHandle = nil
        }

        if isOnlineBattle, let battleId = onlineBattleId {
            Task {
                try? await battleService.deleteBattle(battleId: battleId)
            }
        }

        currentBattle = nil
        selectedTeam = []
        battlePhase = .setup
        isPlayerTurn = true
        showBattleResult = false
        lastLogMessages = []
        isOnlineBattle = false
        waitingForOpponent = false
        onlineBattleId = nil
        onlineOpponentId = nil
        lastAppliedLogCount = 0
        isResolvingTurn = false
        amPlayer1 = true
        cancelMatchmaking()
    }

    // MARK: - Log Animation

    private func animateLogMessages(_ messages: [String], completion: @escaping () -> Void) {
        guard !messages.isEmpty else {
            completion()
            return
        }

        var delay = 0.0
        for (i, msg) in messages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.lastLogMessages.append(msg)
                }

                if msg.contains("took") && msg.contains("damage") {
                    if let battle = self.currentBattle {
                        let p1Name = battle.player1Active.name
                        if msg.contains(p1Name) {
                            self.triggerShake(isPlayer1: true)
                        } else {
                            self.triggerShake(isPlayer1: false)
                        }
                    }
                }

                if i == messages.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        completion()
                    }
                }
            }
            delay += 0.6
        }
    }

    private func triggerShake(isPlayer1: Bool) {
        if isPlayer1 {
            shakePlayer1 = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.shakePlayer1 = false }
        } else {
            shakePlayer2 = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.shakePlayer2 = false }
        }
    }
}
