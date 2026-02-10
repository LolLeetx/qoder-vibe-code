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

    private let storageKey = "categoryXP"

    init() {
        loadXP()
    }

    func awardXP(amount: Int, to category: TaskCategory) -> [XPEvent] {
        let oldXP = categoryXP[category] ?? 0
        let newXP = oldXP + amount
        categoryXP[category] = newXP
        saveXP()

        var events: [XPEvent] = []
        events.append(.xpGained(category: category, amount: amount, total: newXP))

        // Check milestone crossings
        let thresholds: [(Int, (TaskCategory) -> XPEvent)] = [
            (GameConstants.stage1Threshold, { .creatureUnlocked(category: $0) }),
            (GameConstants.stage2Threshold, { .creatureEvolved(category: $0, newStage: 2) }),
            (GameConstants.stage3Threshold, { .creatureEvolved(category: $0, newStage: 3) })
        ]

        for (threshold, eventMaker) in thresholds {
            if oldXP < threshold && newXP >= threshold {
                let event = eventMaker(category)
                events.append(event)
            }
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
