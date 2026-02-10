import Foundation
import Combine
import SwiftUI

class CreatureViewModel: ObservableObject {
    @Published var creatures: [Creature] = []
    @Published var showEvolution: Bool = false
    @Published var evolvingCreature: Creature?
    @Published var newCreatureEvent: String?

    private var cancellables = Set<AnyCancellable>()
    private var storageKey = "creatures"
    private let xpManager = XPManager.shared

    init() {
        subscribeToXPEvents()
    }

    func setUser(_ userId: String) {
        storageKey = "creatures_\(userId)"
        loadCreatures()
    }

    func clearData() {
        creatures = []
    }

    func linkTaskVM(_ taskVM: TaskViewModel) {
        // Re-subscribe to pick up shared XPManager events
    }

    private func subscribeToXPEvents() {
        xpManager.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleEvent(_ event: XPEvent) {
        switch event {
        case .creatureUnlocked(let category):
            // Create a new Stage 1 creature (allows multiples per category)
            var creature = Creature(category: category, stage: 1)
            creature.currentXP = xpManager.xp(for: category)
            creatures.append(creature)
            renumberCreatures()
            evolvingCreature = creatures.last
            showEvolution = true
            saveCreatures()

        case .creatureEvolved(let category, let newStage):
            // Evolve the first creature of this category that is one stage below
            if let index = creatures.firstIndex(where: { $0.category == category && $0.stage == newStage - 1 }) {
                creatures[index].evolve(to: newStage)
                creatures[index].currentXP = xpManager.xp(for: category)
                renumberCreatures()
                evolvingCreature = creatures[index]
                showEvolution = true
                saveCreatures()
            }

        case .xpGained(let category, _, let total):
            // Update XP on all creatures of this category
            for i in creatures.indices where creatures[i].category == category {
                creatures[i].currentXP = total
            }
            saveCreatures()
        }
    }

    /// Renumber creatures that share the same base name (e.g. "Vitaleaf 1", "Vitaleaf 2")
    private func renumberCreatures() {
        // Group creature indices by their base name (derived from category + stage)
        var nameGroups: [String: [Int]] = [:]
        for (index, creature) in creatures.enumerated() {
            let names = creature.category.creatureNames
            let baseName = names[min(creature.stage - 1, names.count - 1)]
            nameGroups[baseName, default: []].append(index)
        }

        for (baseName, indices) in nameGroups {
            if indices.count == 1 {
                // Only one creature with this name — no number needed
                creatures[indices[0]].name = baseName
            } else {
                // Multiple creatures — number them
                for (i, index) in indices.enumerated() {
                    creatures[index].name = "\(baseName) \(i + 1)"
                }
            }
        }
    }

    var battleReady: [Creature] {
        creatures.filter { !$0.isFainted }
    }

    func healAll() {
        for i in creatures.indices {
            creatures[i].heal()
        }
        saveCreatures()
    }

    // MARK: - Persistence

    private func saveCreatures() {
        if let data = try? JSONEncoder().encode(creatures) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadCreatures() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([Creature].self, from: data) else { return }
        creatures = saved
    }
}
