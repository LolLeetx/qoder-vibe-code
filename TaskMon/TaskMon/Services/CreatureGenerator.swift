import Foundation

enum CreatureGenerator {
    /// Generate a creature for a given category and stage
    static func generate(category: TaskCategory, stage: Int, level: Int = 1) -> Creature {
        return Creature(category: category, stage: stage, level: level)
    }

    /// Generate a random team for AI battles
    static func generateAITeam(count: Int = 3, stageRange: ClosedRange<Int> = 1...3) -> [Creature] {
        let categories = TaskCategory.allCases.shuffled()
        var team: [Creature] = []
        for i in 0..<min(count, categories.count) {
            let stage = Int.random(in: stageRange)
            let level = stage * 3 + Int.random(in: 0...5)
            var creature = generate(category: categories[i], stage: stage, level: level)
            // Recalculate stats with the random level
            creature.stats = CreatureStats.base(for: categories[i], stage: stage, level: level)
            team.append(creature)
        }
        return team
    }

    /// Generate a team that matches the player's creature power level
    static func generateMatchedAITeam(playerTeam: [Creature]) -> [Creature] {
        let avgStage = playerTeam.map(\.stage).reduce(0, +) / max(1, playerTeam.count)
        let avgLevel = playerTeam.map(\.level).reduce(0, +) / max(1, playerTeam.count)

        let stageMin = max(1, avgStage - 1)
        let stageMax = min(3, avgStage + 1)

        let categories = TaskCategory.allCases.shuffled()
        var team: [Creature] = []
        for i in 0..<min(playerTeam.count, categories.count) {
            let stage = Int.random(in: stageMin...stageMax)
            let level = max(1, avgLevel + Int.random(in: -2...2))
            var creature = generate(category: categories[i], stage: stage, level: level)
            creature.stats = CreatureStats.base(for: categories[i], stage: stage, level: level)
            team.append(creature)
        }
        return team
    }
}
