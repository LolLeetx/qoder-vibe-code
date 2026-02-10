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
    @Published var turnSecondsRemaining: Int = 30

    private var matchmakingTimer: Timer?
    private var turnTimer: Timer?
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

    static let turnTimeLimit = 30

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

    // MARK: - Turn Timer

    private func startTurnTimer() {
        turnTimer?.invalidate()
        turnSecondsRemaining = Self.turnTimeLimit

        turnTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.turnSecondsRemaining -= 1
                if self.turnSecondsRemaining <= 0 {
                    self.turnTimer?.invalidate()
                    self.turnTimer = nil
                    self.handleTurnTimeout()
                }
            }
        }
    }

    private func stopTurnTimer() {
        turnTimer?.invalidate()
        turnTimer = nil
    }

    private func handleTurnTimeout() {
        guard let battle = currentBattle, !battle.isOver else { return }

        if isOnlineBattle {
            // Only auto-submit if it's our turn
            if isPlayerTurn {
                let creature = battle.player1Active
                let randomMove = Int.random(in: 0..<max(1, creature.moves.count))
                playerSelectMove(randomMove)
            }
        } else {
            // Local: it's always our turn when timer runs, auto-pick random move
            let creature = battle.player1Active
            let randomMove = Int.random(in: 0..<max(1, creature.moves.count))
            playerSelectMove(randomMove)
        }
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
        startTurnTimer()
    }

    // MARK: - Player Actions

    func playerSelectMove(_ moveIndex: Int) {
        guard let battle = currentBattle, !battle.isOver, isPlayerTurn else { return }

        if isOnlineBattle {
            submitOnlineAction(.useMove(moveIndex))
        } else {
            resolveLocalAction(playerAction: .useMove(moveIndex))
        }
    }

    func playerSwitchCreature(_ index: Int) {
        guard let battle = currentBattle, !battle.isOver, isPlayerTurn else { return }

        if isOnlineBattle {
            submitOnlineAction(.switchCreature(index))
        } else {
            resolveLocalAction(playerAction: .switchCreature(index))
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
            stopTurnTimer()
        }
    }

    // MARK: - Local Turn Resolution (Alternating)

    private func resolveLocalAction(playerAction: BattleAction) {
        guard var battle = currentBattle else { return }

        isPlayerTurn = false
        stopTurnTimer()

        // Resolve player's action
        let oldLog = battle.battleLog.count
        BattleEngine.executeAction(battle: &battle, action: playerAction)

        let newMessages = Array(battle.battleLog.dropFirst(oldLog))
        currentBattle = battle

        animateLogMessages(newMessages) {
            if battle.isOver {
                self.battlePhase = .finished
                self.playerWon = battle.winnerId == self.playerId
                self.showBattleResult = true
            } else {
                // AI's turn — auto-execute after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.resolveAITurn()
                }
            }
        }
    }

    private func resolveAITurn() {
        guard var battle = currentBattle, !battle.isOver else { return }

        let aiAction = BattleEngine.selectAIAction(battle: battle)
        let oldLog = battle.battleLog.count
        BattleEngine.executeAction(battle: &battle, action: aiAction)

        let newMessages = Array(battle.battleLog.dropFirst(oldLog))
        currentBattle = battle

        animateLogMessages(newMessages) {
            if battle.isOver {
                self.battlePhase = .finished
                self.playerWon = battle.winnerId == self.playerId
                self.showBattleResult = true
            } else {
                // Back to player's turn
                self.isPlayerTurn = true
                self.startTurnTimer()
            }
        }
    }

    // MARK: - Online Action Submission

    private func submitOnlineAction(_ action: BattleAction) {
        guard let battleId = onlineBattleId else { return }

        isPlayerTurn = false
        waitingForOpponent = true
        stopTurnTimer()

        if amPlayer1 {
            // Host: resolve action locally and push
            resolveOnlineAction(action)
        } else {
            // Non-host: write pending action for host to resolve
            Task {
                try? await battleService.setPlayerAction(
                    battleId: battleId,
                    isPlayer1: false,
                    action: action
                )
            }
        }
    }

    /// Host resolves an action (either its own or the opponent's) and pushes result
    private func resolveOnlineAction(_ action: BattleAction) {
        guard var battle = currentBattle, !battle.isOver else { return }

        isResolvingTurn = true
        let oldLog = battle.battleLog.count

        BattleEngine.executeAction(battle: &battle, action: action)
        battle.pendingAction = nil

        currentBattle = battle

        let newMessages = friendlyLog(Array(battle.battleLog.dropFirst(oldLog)))
        lastAppliedLogCount = battle.battleLog.count

        animateLogMessages(newMessages) {
            if battle.isOver {
                self.battlePhase = .finished
                self.playerWon = battle.winnerId == self.playerId
                self.showBattleResult = true
                self.waitingForOpponent = false
                self.stopTurnTimer()
            } else {
                // Check if it's now our turn
                let isMyTurn = battle.activePlayerId == self.playerId
                self.isPlayerTurn = isMyTurn
                self.waitingForOpponent = !isMyTurn
                if isMyTurn {
                    self.startTurnTimer()
                }
            }
        }

        // Push updated battle to Firebase
        Task {
            try? await battleService.createBattle(battle)
            await MainActor.run {
                self.isResolvingTurn = false
            }
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

                // Clean up any stale queue entry from a previous session
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
                // Player1 (host) goes first
                battle.activePlayerId = sortedIds[0]
                battle.addLog("Match found!")
                battle.addLog("\(sortedIds[0]) sent out \(myTeam[0].name)!")
                battle.addLog("\(sortedIds[1]) sent out \(oppTeam[0].name)!")

                // Set battle state immediately
                currentBattle = battle
                battlePhase = .fighting
                isPlayerTurn = true // Host goes first
                waitingForOpponent = false
                lastLogMessages = friendlyLog(battle.battleLog)
                lastAppliedLogCount = battle.battleLog.count
                startTurnTimer()
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
            if !amPlayer1 {
                var myTeam = selectedTeam
                for i in myTeam.indices { myTeam[i].heal() }
                displayBattle.player1Team = myTeam
                print("[Match] Non-host using local team: \(myTeam.map{$0.name})")
                print("[Match] Non-host opponent team: \(displayBattle.player2Team.map{$0.name})")

                // Confirm our actual team to the host
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
            lastLogMessages = friendlyLog(displayBattle.battleLog)
            lastAppliedLogCount = displayBattle.battleLog.count

            // Determine whose turn it is
            let isMyTurn = remoteBattle.activePlayerId == playerId
            isPlayerTurn = isMyTurn
            waitingForOpponent = !isMyTurn
            if isMyTurn {
                startTurnTimer()
            }
            return
        }

        // Host: check if opponent submitted a pending action
        if amPlayer1 && !isResolvingTurn {
            // Check for opponent's action (player2Action in raw battle)
            if let opponentAction = remoteBattle.pendingAction,
               remoteBattle.activePlayerId == remoteBattle.player2Id {
                // Opponent submitted their action, resolve it
                resolveOnlineAction(opponentAction)
                return
            }

        }

        // Non-host: apply state updates from host's resolution
        if !amPlayer1 {
            let newLogCount = displayBattle.battleLog.count
            if newLogCount > lastAppliedLogCount {
                let newMessages = friendlyLog(Array(displayBattle.battleLog.dropFirst(lastAppliedLogCount)))
                lastAppliedLogCount = newLogCount

                // Merge remote changes into local battle
                if var local = currentBattle {
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
                    local.activePlayerId = displayBattle.activePlayerId
                    local.pendingAction = nil
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
                        self.stopTurnTimer()
                    } else {
                        // Check whose turn it is now
                        let isMyTurn = remoteBattle.activePlayerId == self.playerId
                        self.isPlayerTurn = isMyTurn
                        self.waitingForOpponent = !isMyTurn
                        if isMyTurn {
                            self.startTurnTimer()
                        } else {
                            self.stopTurnTimer()
                        }
                    }
                }
            }
        }

        // Host: also handle state updates for log sync
        if amPlayer1 {
            let newLogCount = displayBattle.battleLog.count
            if newLogCount > lastAppliedLogCount && !isResolvingTurn {
                lastAppliedLogCount = newLogCount
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
        // Don't swap activePlayerId — it stays as the raw ID
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

        stopTurnTimer()
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
        turnSecondsRemaining = Self.turnTimeLimit
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
