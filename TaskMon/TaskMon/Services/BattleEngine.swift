import Foundation

class BattleEngine {
    /// Resolve a single player's action (alternating turn system)
    static func executeAction(battle: inout Battle, action: BattleAction) {
        let isPlayer1Acting = battle.isPlayer1Turn

        // Handle forfeit
        if action.type == .forfeit {
            let forfeiterId = isPlayer1Acting ? battle.player1Id : battle.player2Id
            let winnerId = isPlayer1Acting ? battle.player2Id : battle.player1Id
            battle.addLog("\(forfeiterId) forfeited!")
            battle.winnerId = winnerId
            battle.status = .finished
            return
        }

        // Handle switch
        if action.type == .switchCreature {
            let idx = action.index
            if isPlayer1Acting {
                if idx >= 0 && idx < battle.player1Team.count && !battle.player1Team[idx].isFainted {
                    battle.player1ActiveIndex = idx
                    battle.addLog("\(battle.player1Id) sent out \(battle.player1Team[idx].name)!")
                }
            } else {
                if idx >= 0 && idx < battle.player2Team.count && !battle.player2Team[idx].isFainted {
                    battle.player2ActiveIndex = idx
                    battle.addLog("\(battle.player2Id) sent out \(battle.player2Team[idx].name)!")
                }
            }
            battle.switchTurn()
            return
        }

        // Handle move
        if action.type == .useMove {
            executeMove(battle: &battle, attackerIsPlayer1: isPlayer1Acting, moveIndex: action.index)

            // Check for fainting on the defender side
            handleFainting(battle: &battle, isPlayer1: !isPlayer1Acting)

            // Check win condition
            checkWinCondition(battle: &battle)

            // If battle isn't over, switch turn
            if !battle.isOver {
                battle.switchTurn()
            }
        }
    }

    private static func executeMove(battle: inout Battle, attackerIsPlayer1: Bool, moveIndex: Int) {
        let attacker: Creature
        let defender: Creature

        if attackerIsPlayer1 {
            attacker = battle.player1Team[battle.player1ActiveIndex]
            defender = battle.player2Team[battle.player2ActiveIndex]
        } else {
            attacker = battle.player2Team[battle.player2ActiveIndex]
            defender = battle.player1Team[battle.player1ActiveIndex]
        }

        guard moveIndex >= 0 && moveIndex < attacker.moves.count else { return }
        let move = attacker.moves[moveIndex]

        // Damage formula
        let typeMultiplier = TypeEffectiveness.multiplier(attacking: move.type, defending: defender.category)
        let baseDamage = Double(attacker.stats.attack * move.power) / Double(max(1, defender.stats.defense))
        let variance = Double.random(in: 0.85...1.15)
        let damage = max(1, Int(baseDamage * typeMultiplier * variance * 0.5))

        battle.addLog("\(attacker.name) used \(move.name)!")

        if let effectText = TypeEffectiveness.effectivenessText(attacking: move.type, defending: defender.category) {
            battle.addLog(effectText)
        }

        battle.addLog("\(defender.name) took \(damage) damage!")

        // Apply damage
        if attackerIsPlayer1 {
            battle.player2Team[battle.player2ActiveIndex].takeDamage(damage)
        } else {
            battle.player1Team[battle.player1ActiveIndex].takeDamage(damage)
        }
    }

    private static func handleFainting(battle: inout Battle, isPlayer1: Bool) {
        let team = isPlayer1 ? battle.player1Team : battle.player2Team
        let activeIndex = isPlayer1 ? battle.player1ActiveIndex : battle.player2ActiveIndex

        guard team[activeIndex].isFainted else { return }

        let name = team[activeIndex].name
        battle.addLog("\(name) fainted!")

        // Find next available creature
        if let nextIndex = team.indices.first(where: { $0 != activeIndex && !team[$0].isFainted }) {
            if isPlayer1 {
                battle.player1ActiveIndex = nextIndex
            } else {
                battle.player2ActiveIndex = nextIndex
            }
            let nextName = team[nextIndex].name
            let playerId = isPlayer1 ? battle.player1Id : battle.player2Id
            battle.addLog("\(playerId) sent out \(nextName)!")
        }
    }

    private static func checkWinCondition(battle: inout Battle) {
        let p1AllFainted = battle.player1Team.allSatisfy { $0.isFainted }
        let p2AllFainted = battle.player2Team.allSatisfy { $0.isFainted }

        if p1AllFainted && p2AllFainted {
            battle.addLog("It's a draw!")
            battle.status = .finished
        } else if p1AllFainted {
            battle.addLog("\(battle.player2Id) wins!")
            battle.winnerId = battle.player2Id
            battle.status = .finished
        } else if p2AllFainted {
            battle.addLog("\(battle.player1Id) wins!")
            battle.winnerId = battle.player1Id
            battle.status = .finished
        }
    }

    // MARK: - AI

    /// Simple AI: picks the most effective move against the opponent
    static func selectAIAction(battle: Battle) -> BattleAction {
        let aiCreature = battle.player2Active
        let playerCreature = battle.player1Active

        guard !aiCreature.moves.isEmpty else { return .useMove(0) }

        // Pick the move with best damage (considering type effectiveness)
        var bestIndex = 0
        var bestScore: Double = -1

        for (i, move) in aiCreature.moves.enumerated() {
            let mult = TypeEffectiveness.multiplier(attacking: move.type, defending: playerCreature.category)
            let score = Double(move.power) * mult
            if score > bestScore {
                bestScore = score
                bestIndex = i
            }
        }

        return .useMove(bestIndex)
    }
}
