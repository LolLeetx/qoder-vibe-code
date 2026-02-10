import Foundation

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    var displayName: String
    var photoURL: String?
    var wins: Int
    var losses: Int
    var creatureCount: Int
    var totalXP: Int

    var winRate: Double {
        let total = wins + losses
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total) * 100
    }
}
