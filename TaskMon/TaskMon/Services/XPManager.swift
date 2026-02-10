import Foundation
import Combine

enum XPEvent {
    case xpGained(category: TaskCategory, amount: Int, total: Int)
    case creatureUnlocked(category: TaskCategory)
    case creatureEvolved(category: TaskCategory, newStage: Int)
}

class XPManager: ObservableObject {
    static let shared = XPManager()

    @Published var categoryXP: [TaskCategory: Int] = [:]
    let eventPublisher = PassthroughSubject<XPEvent, Never>()

    private var storageKey = "categoryXP"

    init() {}

    func setUser(_ userId: String) {
        storageKey = "categoryXP_\(userId)"
        categoryXP = [:]
        loadXP()
    }

    func awardXP(amount: Int, to category: TaskCategory) -> [XPEvent] {
        let oldXP = categoryXP[category] ?? 0
        let newXP = oldXP + amount
        categoryXP[category] = newXP
        saveXP()

        var events: [XPEvent] = []
        events.append(.xpGained(category: category, amount: amount, total: newXP))

        // Check for new creature spawn (every 100 XP spawns a new Stage 1 creature)
        let spawnInterval = GameConstants.stage1Threshold
        let oldSpawns = max(0, oldXP / spawnInterval)
        let newSpawns = max(0, newXP / spawnInterval)
        for _ in 0..<(newSpawns - oldSpawns) {
            events.append(.creatureUnlocked(category: category))
        }

        // Check evolution thresholds (evolves one existing creature)
        if oldXP < GameConstants.stage2Threshold && newXP >= GameConstants.stage2Threshold {
            events.append(.creatureEvolved(category: category, newStage: 2))
        }
        if oldXP < GameConstants.stage3Threshold && newXP >= GameConstants.stage3Threshold {
            events.append(.creatureEvolved(category: category, newStage: 3))
        }

        for event in events {
            eventPublisher.send(event)
        }

        return events
    }

    func xp(for category: TaskCategory) -> Int {
        categoryXP[category] ?? 0
    }

    func nextMilestone(for category: TaskCategory) -> Int {
        let xp = xp(for: category)
        let thresholds = [
            GameConstants.stage1Threshold,
            GameConstants.stage2Threshold,
            GameConstants.stage3Threshold
        ]
        for t in thresholds {
            if xp < t { return t }
        }
        return thresholds.last! // maxed out
    }

    func currentStage(for category: TaskCategory) -> Int {
        let xp = xp(for: category)
        if xp >= GameConstants.stage3Threshold { return 3 }
        if xp >= GameConstants.stage2Threshold { return 2 }
        if xp >= GameConstants.stage1Threshold { return 1 }
        return -1 // nothing yet
    }

    // MARK: - Persistence

    private func saveXP() {
        let dict = Dictionary(uniqueKeysWithValues: categoryXP.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadXP() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else { return }
        for (key, value) in dict {
            if let category = TaskCategory(rawValue: key) {
                categoryXP[category] = value
            }
        }
    }
}
