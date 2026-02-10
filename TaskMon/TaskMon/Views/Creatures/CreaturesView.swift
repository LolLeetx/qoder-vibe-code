import SwiftUI

struct CreaturesView: View {
    @EnvironmentObject var creatureVM: CreatureViewModel
    @State private var selectedCreature: Creature?
    @State private var filterCategory: TaskCategory?

    private var filteredCreatures: [Creature] {
        if let cat = filterCategory {
            return creatureVM.creatures.filter { $0.category == cat }
        }
        return creatureVM.creatures
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PixelColors.background.ignoresSafeArea()

                if creatureVM.creatures.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Filter bar
                            filterBar

                            // Creature grid
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(filteredCreatures) { creature in
                                    CreatureCardView(creature: creature)
                                        .onTapGesture {
                                            selectedCreature = creature
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PixelTitle(text: "CREATURES", color: PixelColors.accent)
                }
            }
            .sheet(item: $selectedCreature) { creature in
                CreatureDetailView(creature: creature)
            }
            .overlay {
                if creatureVM.showEvolution, let creature = creatureVM.evolvingCreature {
                    EvolutionAnimationView(creature: creature) {
                        creatureVM.showEvolution = false
                        creatureVM.evolvingCreature = nil
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .animation(.spring(response: 0.4), value: creatureVM.showEvolution)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 56))
                .foregroundColor(.gray.opacity(0.4))
            PixelText(text: "No creatures yet!", size: 18, color: .gray)
            PixelText(text: "Complete tasks to earn XP", size: 13, color: .gray.opacity(0.7))
            PixelText(text: "and unlock your first creature!", size: 13, color: .gray.opacity(0.7))

            VStack(alignment: .leading, spacing: 6) {
                milestoneRow("100 XP", "Creature unlocked (Stage 1)")
                milestoneRow("500 XP", "Evolves (Stage 2)")
                milestoneRow("1000 XP", "Final form (Stage 3)")
            }
            .padding()
            .background(PixelColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(PixelColors.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }

    private func milestoneRow(_ xp: String, _ label: String) -> some View {
        HStack(spacing: 8) {
            PixelText(text: xp, size: 11, color: PixelColors.gold)
                .frame(width: 60, alignment: .trailing)
            PixelText(text: label, size: 11, color: .white)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: filterCategory == nil) {
                    filterCategory = nil
                }
                ForEach(TaskCategory.allCases) { cat in
                    FilterChip(title: cat.displayName, color: cat.color, isSelected: filterCategory == cat) {
                        filterCategory = cat
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    var color: Color = PixelColors.accent
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
