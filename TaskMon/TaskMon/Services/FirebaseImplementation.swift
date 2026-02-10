import Foundation
import Combine

// This file contains the Firebase-backed implementations.
// To enable Firebase:
// 1. Add Firebase SDK via SPM (FirebaseAuth, FirebaseFirestore, FirebaseDatabase)
// 2. Add GoogleService-Info.plist to your project
// 3. Uncomment the `import Firebase*` lines and the real implementations
// 4. Switch from Stub* to Firebase* services in ServiceContainer

// Uncomment when Firebase is configured:
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import FirebaseCore
import GoogleSignIn


// MARK: - Firebase Auth Service

class FirebaseAuthService: AuthServiceProtocol {
    private(set) var currentUserId: String?
    private(set) var displayName: String?
    private(set) var email: String?
    private(set) var photoURL: String?

    var isAuthenticated: Bool { currentUserId != nil }

    init() {
        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
            displayName = user.displayName
            email = user.email
            photoURL = user.photoURL?.absoluteString
        }
    }

    func signInAnonymously() async throws -> String {
        let result = try await Auth.auth().signInAnonymously()
        currentUserId = result.user.uid
        return result.user.uid
    }

    func signInWithGoogle(presenting viewController: UIViewController) async throws -> String {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID. Enable Google Sign-In in Firebase Console."])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token"])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let user = authResult.user
        currentUserId = user.uid
        displayName = user.displayName
        email = user.email
        photoURL = user.photoURL?.absoluteString
        return user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        currentUserId = nil
        displayName = nil
        email = nil
        photoURL = nil
    }
}

// MARK: - Firestore Database Service

class FirestoreDatabaseService: DatabaseServiceProtocol {
    private let db = Firestore.firestore()

    func savePlayer(_ player: Player) async throws {
        let data = try JSONEncoder().encode(player)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await db.collection("users").document(player.id).setData(dict, merge: true)
    }

    func loadPlayer(userId: String) async throws -> Player? {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data() else { return nil }
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(Player.self, from: jsonData)
    }

    func saveTasks(_ tasks: [TaskItem], userId: String) async throws {
        let batch = db.batch()
        let tasksRef = db.collection("users").document(userId).collection("tasks")
        for task in tasks {
            let data = try JSONEncoder().encode(task)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            batch.setData(dict, forDocument: tasksRef.document(task.id.uuidString))
        }
        try await batch.commit()
    }

    func loadTasks(userId: String) async throws -> [TaskItem] {
        let snapshot = try await db.collection("users").document(userId).collection("tasks").getDocuments()
        return snapshot.documents.compactMap { doc in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: doc.data()) else { return nil }
            return try? JSONDecoder().decode(TaskItem.self, from: jsonData)
        }
    }

    func saveCreatures(_ creatures: [Creature], userId: String) async throws {
        let batch = db.batch()
        let creaturesRef = db.collection("users").document(userId).collection("creatures")
        for creature in creatures {
            let data = try JSONEncoder().encode(creature)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            batch.setData(dict, forDocument: creaturesRef.document(creature.id.uuidString))
        }
        try await batch.commit()
    }

    func loadCreatures(userId: String) async throws -> [Creature] {
        let snapshot = try await db.collection("users").document(userId).collection("creatures").getDocuments()
        return snapshot.documents.compactMap { doc in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: doc.data()) else { return nil }
            return try? JSONDecoder().decode(Creature.self, from: jsonData)
        }
    }

    func saveLeaderboardEntry(_ entry: LeaderboardEntry) async throws {
        let data = try JSONEncoder().encode(entry)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await db.collection("leaderboard").document(entry.id).setData(dict, merge: true)
    }

    func loadLeaderboard(limit: Int) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection("leaderboard")
            .order(by: "wins", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: doc.data()) else { return nil }
            return try? JSONDecoder().decode(LeaderboardEntry.self, from: jsonData)
        }
    }
}

// MARK: - Realtime Database Battle Service

class FirebaseRealtimeBattleService: RealtimeBattleServiceProtocol {
    private let rtdb = Database.database(url: "https://qoder-vibe-code-default-rtdb.asia-southeast1.firebasedatabase.app").reference()

    /// Firebase RTDB converts Int to Double and arrays to dicts with string keys.
    /// This recursively normalizes the data so JSONDecoder can handle it.
    private func normalizeFirebaseValue(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            // Check if this is actually an array (keys are "0", "1", "2", ...)
            let isArray = !dict.isEmpty && dict.keys.allSatisfy({ Int($0) != nil })
            if isArray {
                let sorted = dict.sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
                return sorted.map { normalizeFirebaseValue($0.value) }
            }
            return dict.mapValues { normalizeFirebaseValue($0) }
        }
        if let array = value as? [Any] {
            return array.map { normalizeFirebaseValue($0) }
        }
        // Convert whole-number Doubles to Int for JSONDecoder compatibility
        if let double = value as? Double, double == double.rounded(), double >= Double(Int.min), double <= Double(Int.max) {
            return Int(double)
        }
        return value
    }

    private func decodeFromFirebase<T: Decodable>(_ type: T.Type, value: Any) throws -> T {
        let normalized = normalizeFirebaseValue(value)
        let data = try JSONSerialization.data(withJSONObject: normalized)
        return try JSONDecoder().decode(type, from: data)
    }

    func createBattle(_ battle: Battle) async throws {
        let data = try JSONEncoder().encode(battle)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await rtdb.child("battles").child(battle.id).setValue(dict)
    }

    func observeBattle(battleId: String, onChange: @escaping (Battle) -> Void) -> Any {
        let handle = rtdb.child("battles").child(battleId).observe(.value) { [weak self] snapshot in
            guard let self, snapshot.exists(),
                  let value = snapshot.value as? [String: Any] else { return }
            do {
                let battle = try self.decodeFromFirebase(Battle.self, value: value)
                onChange(battle)
            } catch {
                print("[observeBattle] Decode error: \(error)")
            }
        }
        return handle
    }

    func submitAction(battleId: String, playerId: String, action: BattleAction) async throws {
        let data = try JSONEncoder().encode(action)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await rtdb.child("battles").child(battleId).child("actions").child(playerId).setValue(dict)
    }

    func setPlayerAction(battleId: String, isPlayer1: Bool, action: BattleAction) async throws {
        let data = try JSONEncoder().encode(action)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let field = isPlayer1 ? "player1Action" : "player2Action"
        try await rtdb.child("battles").child(battleId).child(field).setValue(dict)
    }

    func joinQueue(playerId: String, team: [Creature]) async throws {
        // Store team as a JSON string to avoid Firebase RTDB mangling types
        let teamData = try JSONEncoder().encode(team)
        let teamJSON = String(data: teamData, encoding: .utf8) ?? "[]"
        let entry: [String: Any] = [
            "playerId": playerId,
            "teamJSON": teamJSON,
            "timestamp": ServerValue.timestamp()
        ]
        try await rtdb.child("queue").child(playerId).setValue(entry)
    }

    func leaveQueue(playerId: String) async throws {
        try await rtdb.child("queue").child(playerId).removeValue()
    }

    func observeQueue(onMatchFound: @escaping (String, String) -> Void) -> Any {
        let handle = rtdb.child("queue").observe(.value) { snapshot in
            guard let children = snapshot.children.allObjects as? [DataSnapshot],
                  children.count >= 2 else { return }

            // Simple matchmaking: match first two players
            let player1Id = children[0].key
            let player2Id = children[1].key
            onMatchFound(player1Id, player2Id)
        }
        return handle
    }

    func deleteBattle(battleId: String) async throws {
        try await rtdb.child("battles").child(battleId).removeValue()
    }

    func fetchQueueEntry(playerId: String) async throws -> [Creature]? {
        let snapshot = try await rtdb.child("queue").child(playerId).getData()
        guard let value = snapshot.value as? [String: Any] else {
            print("[fetchQueueEntry] No data found for \(playerId)")
            return nil
        }

        // Prefer JSON string (no Firebase type mangling)
        if let teamJSON = value["teamJSON"] as? String,
           let jsonData = teamJSON.data(using: .utf8) {
            let creatures = try JSONDecoder().decode([Creature].self, from: jsonData)
            print("[fetchQueueEntry] Decoded \(creatures.count) creatures: \(creatures.map { $0.name })")
            return creatures
        }

        // Fallback: nested object with normalization
        if let teamData = value["team"] {
            let creatures = try decodeFromFirebase([Creature].self, value: teamData)
            print("[fetchQueueEntry] Decoded \(creatures.count) creatures from legacy format")
            return creatures
        }

        print("[fetchQueueEntry] No team data in any format for \(playerId)")
        return nil
    }

    func removeObserver(_ handle: Any) {
        if let h = handle as? UInt {
            rtdb.removeObserver(withHandle: h)
        }
    }
}


// MARK: - Service Container

class ServiceContainer {
    static let shared = ServiceContainer()

    // Swap these to Firebase implementations when configured
    let auth: AuthServiceProtocol = FirebaseAuthService()
    let database: DatabaseServiceProtocol = FirestoreDatabaseService()
    let realtimeBattle: RealtimeBattleServiceProtocol = FirebaseRealtimeBattleService()
}
