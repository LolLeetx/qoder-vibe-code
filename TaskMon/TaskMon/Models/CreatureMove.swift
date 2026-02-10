import Foundation

struct CreatureMove: Identifiable, Codable {
    let id: UUID
    let name: String
    let power: Int
    let type: TaskCategory
    let description: String

    init(name: String, power: Int, type: TaskCategory, description: String = "") {
        self.id = UUID()
        self.name = name
        self.power = power
        self.type = type
        self.description = description
    }
}

// MARK: - Move Pools

enum MovePools {
    static func moves(for category: TaskCategory, stage: Int) -> [CreatureMove] {
        let pool = allMoves(for: category)
        let count = min(1 + stage, pool.count) // stage 1 = 2 moves, stage 2 = 3, stage 3 = 4
        return Array(pool.prefix(count))
    }

    private static func allMoves(for category: TaskCategory) -> [CreatureMove] {
        switch category {
        case .work:
            return [
                CreatureMove(name: "Grind", power: 20, type: .work, description: "A steady, reliable attack."),
                CreatureMove(name: "Deadline Slam", power: 35, type: .work, description: "Powered by urgency!"),
                CreatureMove(name: "Overtime Strike", power: 50, type: .work, description: "Extra effort, extra damage."),
                CreatureMove(name: "Corporate Crush", power: 70, type: .work, description: "Devastating executive power.")
            ]
        case .health:
            return [
                CreatureMove(name: "Leaf Whip", power: 20, type: .health, description: "A refreshing slap."),
                CreatureMove(name: "Vitality Pulse", power: 35, type: .health, description: "Surging life energy."),
                CreatureMove(name: "Nature's Wrath", power: 50, type: .health, description: "The forest fights back."),
                CreatureMove(name: "Rejuvenation Storm", power: 70, type: .health, description: "Overwhelming natural force.")
            ]
        case .learning:
            return [
                CreatureMove(name: "Quick Study", power: 20, type: .learning, description: "Knowledge is power."),
                CreatureMove(name: "Brain Blast", power: 35, type: .learning, description: "A burst of intellect."),
                CreatureMove(name: "Thesis Strike", power: 50, type: .learning, description: "Years of research unleashed."),
                CreatureMove(name: "Enlightenment Beam", power: 70, type: .learning, description: "Pure wisdom, pure destruction.")
            ]
        case .creative:
            return [
                CreatureMove(name: "Spark", power: 20, type: .creative, description: "A flash of inspiration."),
                CreatureMove(name: "Color Burst", power: 35, type: .creative, description: "An explosion of creativity."),
                CreatureMove(name: "Muse Strike", power: 50, type: .creative, description: "Channeling the muses."),
                CreatureMove(name: "Masterpiece Blast", power: 70, type: .creative, description: "A once-in-a-lifetime creation.")
            ]
        case .personal:
            return [
                CreatureMove(name: "Star Tap", power: 20, type: .personal, description: "A gentle cosmic touch."),
                CreatureMove(name: "Nova Flare", power: 35, type: .personal, description: "A burst of starlight."),
                CreatureMove(name: "Cosmic Wave", power: 50, type: .personal, description: "Riding the cosmic tide."),
                CreatureMove(name: "Supernova", power: 70, type: .personal, description: "The ultimate stellar explosion.")
            ]
        }
    }
}
