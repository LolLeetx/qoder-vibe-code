import Foundation

struct CreatureStats: Codable {
    var hp: Int
    var maxHP: Int
    var attack: Int
    var defense: Int
    var speed: Int

    static func base(for category: TaskCategory, stage: Int, level: Int) -> CreatureStats {
        let stageMultiplier = Double(stage) * 0.5 + 0.5 // stage1=1.0, stage2=1.5, stage3=2.0
        let levelBonus = level * 2

        let (baseHP, baseAtk, baseDef, baseSpd): (Int, Int, Int, Int) = {
            switch category {
            case .work:     return (45, 55, 40, 35)  // high attack
            case .health:   return (60, 35, 55, 30)  // high HP + defense
            case .learning: return (40, 45, 45, 50)  // high speed
            case .creative: return (35, 50, 35, 55)  // high speed + attack
            case .personal: return (50, 45, 45, 40)  // balanced
            }
        }()

        let hp = Int(Double(baseHP) * stageMultiplier) + levelBonus
        let atk = Int(Double(baseAtk) * stageMultiplier) + levelBonus
        let def = Int(Double(baseDef) * stageMultiplier) + levelBonus
        let spd = Int(Double(baseSpd) * stageMultiplier) + levelBonus

        return CreatureStats(hp: hp, maxHP: hp, attack: atk, defense: def, speed: spd)
    }
}

struct Creature: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: TaskCategory
    var stage: Int          // 1-3 = evolution stages
    var level: Int
    var currentXP: Int
    var stats: CreatureStats
    var moves: [CreatureMove]
    let createdAt: Date

    var spriteName: String {
        return "\(category.rawValue)_stage\(stage)"
    }

    var evolutionProgress: Double {
        let thresholds = [0, 100, 500, 1000]
        if stage >= 3 { return 1.0 }
        let current = currentXP
        let needed = thresholds[stage]
        let next = thresholds[min(stage + 1, 3)]
        let range = next - needed
        guard range > 0 else { return 1.0 }
        return min(1.0, Double(current - needed) / Double(range))
    }

    var nextEvolutionXP: Int {
        let thresholds = [500, 1000]
        if stage >= 3 { return currentXP }
        if stage >= 2 { return thresholds[1] }
        return thresholds[0]
    }

    init(category: TaskCategory, stage: Int, level: Int = 1, currentXP: Int = 0) {
        self.id = UUID()
        self.category = category
        self.stage = max(1, stage) // minimum stage 1, no eggs
        self.level = level
        self.currentXP = currentXP
        self.createdAt = Date()

        let names = category.creatureNames
        self.name = names[min(self.stage - 1, names.count - 1)]
        self.stats = CreatureStats.base(for: category, stage: self.stage, level: level)
        self.moves = MovePools.moves(for: category, stage: self.stage)
    }

    mutating func evolve(to newStage: Int) {
        self.stage = newStage
        let names = category.creatureNames
        self.name = names[min(newStage - 1, names.count - 1)]
        self.stats = CreatureStats.base(for: category, stage: newStage, level: level)
        self.moves = MovePools.moves(for: category, stage: newStage)
    }

    mutating func takeDamage(_ amount: Int) {
        stats.hp = max(0, stats.hp - amount)
    }

    mutating func heal() {
        stats.hp = stats.maxHP
    }

    var isFainted: Bool { stats.hp <= 0 }
}
