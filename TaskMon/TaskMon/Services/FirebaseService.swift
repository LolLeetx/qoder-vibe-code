import Foundation
import UIKit

// MARK: - Firebase Service Protocols
// These protocols allow stubbing Firebase when it's not configured.
// Replace the stub implementations with real Firebase calls once
// GoogleService-Info.plist is added and Firebase SDK is linked.

protocol AuthServiceProtocol {
    var currentUserId: String? { get }
    var isAuthenticated: Bool { get }
    var displayName: String? { get }
    var email: String? { get }
    var photoURL: String? { get }
    func signInAnonymously() async throws -> String
    func signInWithGoogle(presenting viewController: UIViewController) async throws -> String
    func signOut() throws
}

protocol DatabaseServiceProtocol {
    func savePlayer(_ player: Player) async throws
    func loadPlayer(userId: String) async throws -> Player?
    func saveTasks(_ tasks: [TaskItem], userId: String) async throws
    func loadTasks(userId: String) async throws -> [TaskItem]
    func saveCreatures(_ creatures: [Creature], userId: String) async throws
    func loadCreatures(userId: String) async throws -> [Creature]
    func saveLeaderboardEntry(_ entry: LeaderboardEntry) async throws
    func loadLeaderboard(limit: Int) async throws -> [LeaderboardEntry]
}

protocol RealtimeBattleServiceProtocol {
    func createBattle(_ battle: Battle) async throws
    func observeBattle(battleId: String, onChange: @escaping (Battle) -> Void) -> Any
    func submitAction(battleId: String, playerId: String, action: BattleAction) async throws
    func setPlayerAction(battleId: String, isPlayer1: Bool, action: BattleAction) async throws
    func joinQueue(playerId: String, team: [Creature]) async throws
    func leaveQueue(playerId: String) async throws
    func observeQueue(onMatchFound: @escaping (String, String) -> Void) -> Any
    func fetchQueueEntry(playerId: String) async throws -> [Creature]?
    func confirmPlayerTeam(battleId: String, isPlayer1: Bool, teamJSON: String) async throws
    func deleteBattle(battleId: String) async throws
    func removeObserver(_ handle: Any)
}

// MARK: - Stub Auth Service (works without Firebase)

class StubAuthService: AuthServiceProtocol {
    private(set) var currentUserId: String?
    var displayName: String? { nil }
    var email: String? { nil }
    var photoURL: String? { nil }

    var isAuthenticated: Bool { currentUserId != nil }

    init() {
        if let stored = UserDefaults.standard.string(forKey: "localUserId") {
            currentUserId = stored
        }
    }

    func signInAnonymously() async throws -> String {
        let id = currentUserId ?? UUID().uuidString
        currentUserId = id
        UserDefaults.standard.set(id, forKey: "localUserId")
        return id
    }

    func signInWithGoogle(presenting viewController: UIViewController) async throws -> String {
        throw NSError(domain: "StubAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In not available in stub mode"])
    }

    func signOut() throws {
        currentUserId = nil
        UserDefaults.standard.removeObject(forKey: "localUserId")
    }
}

// MARK: - Stub Database Service (local-only)

class StubDatabaseService: DatabaseServiceProtocol {
    func savePlayer(_ player: Player) async throws {
        if let data = try? JSONEncoder().encode(player) {
            UserDefaults.standard.set(data, forKey: "player_\(player.id)")
        }
    }

    func loadPlayer(userId: String) async throws -> Player? {
        guard let data = UserDefaults.standard.data(forKey: "player_\(userId)"),
              let player = try? JSONDecoder().decode(Player.self, from: data) else { return nil }
        return player
    }

    func saveTasks(_ tasks: [TaskItem], userId: String) async throws {}

    func loadTasks(userId: String) async throws -> [TaskItem] {
        guard let data = UserDefaults.standard.data(forKey: "tasks"),
              let tasks = try? JSONDecoder().decode([TaskItem].self, from: data) else { return [] }
        return tasks
    }

    func saveCreatures(_ creatures: [Creature], userId: String) async throws {}

    func loadCreatures(userId: String) async throws -> [Creature] {
        guard let data = UserDefaults.standard.data(forKey: "creatures"),
              let creatures = try? JSONDecoder().decode([Creature].self, from: data) else { return [] }
        return creatures
    }

    func saveLeaderboardEntry(_ entry: LeaderboardEntry) async throws {}

    func loadLeaderboard(limit: Int) async throws -> [LeaderboardEntry] {
        return []
    }
}

// MARK: - Stub Realtime Battle (local simulation)

class StubRealtimeBattleService: RealtimeBattleServiceProtocol {
    func createBattle(_ battle: Battle) async throws {
        // No-op for local
    }

    func observeBattle(battleId: String, onChange: @escaping (Battle) -> Void) -> Any {
        return "" as Any
    }

    func submitAction(battleId: String, playerId: String, action: BattleAction) async throws {
        // No-op for local
    }

    func setPlayerAction(battleId: String, isPlayer1: Bool, action: BattleAction) async throws {
        // No-op for local
    }

    func joinQueue(playerId: String, team: [Creature]) async throws {
        // No-op for local
    }

    func leaveQueue(playerId: String) async throws {
        // No-op for local
    }

    func observeQueue(onMatchFound: @escaping (String, String) -> Void) -> Any {
        return "" as Any
    }

    func fetchQueueEntry(playerId: String) async throws -> [Creature]? {
        return nil
    }

    func confirmPlayerTeam(battleId: String, isPlayer1: Bool, teamJSON: String) async throws {
        // No-op for local
    }

    func deleteBattle(battleId: String) async throws {
        // No-op for local
    }

    func removeObserver(_ handle: Any) {
        // No-op
    }
}
