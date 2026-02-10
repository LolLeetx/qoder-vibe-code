import Foundation

struct Player: Identifiable, Codable {
    let id: String
    var username: String
    var displayName: String
    var email: String?
    var photoURL: String?
    var creatures: [Creature]
    var categoryXP: [String: Int] // TaskCategory.rawValue -> XP
    var wins: Int
    var losses: Int

    var totalXP: Int {
        categoryXP.values.reduce(0, +)
    }

    init(id: String = UUID().uuidString, username: String = "Trainer", displayName: String = "Trainer", email: String? = nil, photoURL: String? = nil) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.creatures = []
        self.categoryXP = [:]
        self.wins = 0
        self.losses = 0
    }

    func xp(for category: TaskCategory) -> Int {
        categoryXP[category.rawValue] ?? 0
    }

    mutating func addXP(_ amount: Int, for category: TaskCategory) {
        let current = categoryXP[category.rawValue] ?? 0
        categoryXP[category.rawValue] = current + amount
    }

    func toLeaderboardEntry(creatureCount: Int) -> LeaderboardEntry {
        LeaderboardEntry(
            id: id,
            displayName: displayName,
            photoURL: photoURL,
            wins: wins,
            losses: losses,
            creatureCount: creatureCount,
            totalXP: totalXP
        )
    }
}
