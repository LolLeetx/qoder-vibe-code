import Foundation
import Combine
import SwiftUI

class CreatureViewModel: ObservableObject {
    @Published var creatures: [Creature] = []
    @Published var showEvolution: Bool = false
    @Published var evolvingCreature: Creature?
    @Published var newCreatureEvent: String?

    private var cancellables = Set<AnyCancellable>()
    private let storageKey = "creatures"
    private let xpManager = XPManager.shared

    init() {
        loadCreatures()
        subscribeToXPEvents()
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
            // Directly create a Stage 1 creature if we don't have one for this category
            if !creatures.contains(where: { $0.category == category }) {
                var creature = Creature(category: category, stage: 1)
                creature.currentXP = xpManager.xp(for: category)
                creatures.append(creature)
                evolvingCreature = creature
                showEvolution = true
                saveCreatures()
            }

        case .creatureEvolved(let category, let newStage):
            // Find the creature for this category and evolve it
            if let index = creatures.firstIndex(where: { $0.category == category && $0.stage == newStage - 1 }) {
                creatures[index].evolve(to: newStage)
                creatures[index].currentXP = xpManager.xp(for: category)
                evolvingCreature = creatures[index]
                showEvolution = true
                saveCreatures()
            }

        case .xpGained(let category, _, let total):
            // Update XP on the creature
            if let index = creatures.firstIndex(where: { $0.category == category }) {
                creatures[index].currentXP = total
                saveCreatures()
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
