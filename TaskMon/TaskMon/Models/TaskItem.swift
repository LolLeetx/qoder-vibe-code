import Foundation

enum TaskDifficulty: String, CaseIterable, Codable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var xpReward: Int {
        switch self {
        case .easy: return 10
        case .medium: return 25
        case .hard: return 50
        }
    }
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var difficulty: TaskDifficulty
    var isCompleted: Bool
    let createdAt: Date

    init(title: String, category: TaskCategory, difficulty: TaskDifficulty) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.difficulty = difficulty
        self.isCompleted = false
        self.createdAt = Date()
    }
}
