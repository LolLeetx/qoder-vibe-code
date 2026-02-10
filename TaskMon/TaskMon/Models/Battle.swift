import Foundation

enum BattleStatus: String, Codable {
    case setup
    case active
    case finished
}

struct BattleAction: Codable {
    enum ActionType: String, Codable {
        case useMove
        case switchCreature
        case forfeit
    }

    let type: ActionType
    let index: Int // move index or creature index

    static func useMove(_ index: Int) -> BattleAction {
        BattleAction(type: .useMove, index: index)
    }

    static func switchCreature(_ index: Int) -> BattleAction {
        BattleAction(type: .switchCreature, index: index)
    }

    static var forfeit: BattleAction {
        BattleAction(type: .forfeit, index: -1)
    }
}

struct Battle: Identifiable, Codable {
    let id: String
    var player1Id: String
    var player2Id: String
    var player1Team: [Creature]
    var player2Team: [Creature]
    var player1ActiveIndex: Int
    var player2ActiveIndex: Int
    var currentTurn: Int
    var battleLog: [String]
    var status: BattleStatus
    var winnerId: String?
    var activePlayerId: String  // whose turn it is
    var pendingAction: BattleAction?  // action submitted by active player
    var player2TeamJSON: String?

    var player1Active: Creature { player1Team[player1ActiveIndex] }
    var player2Active: Creature { player2Team[player2ActiveIndex] }

    init(player1Id: String, player2Id: String, player1Team: [Creature], player2Team: [Creature], id: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.player1Id = player1Id
        self.player2Id = player2Id
        self.player1Team = player1Team
        self.player2Team = player2Team
        self.player1ActiveIndex = 0
        self.player2ActiveIndex = 0
        self.currentTurn = 1
        self.battleLog = ["Battle Start!"]
        self.status = .active
        // Player 1 goes first
        self.activePlayerId = player1Id
    }

    var isOver: Bool { status == .finished }

    var isPlayer1Turn: Bool { activePlayerId == player1Id }

    mutating func addLog(_ message: String) {
        battleLog.append(message)
    }

    mutating func switchTurn() {
        activePlayerId = isPlayer1Turn ? player2Id : player1Id
        currentTurn += 1
    }
}
