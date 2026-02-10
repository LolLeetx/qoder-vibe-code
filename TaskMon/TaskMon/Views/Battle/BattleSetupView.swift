import SwiftUI

struct BattleSetupView: View {
    @EnvironmentObject var battleVM: BattleViewModel
    @EnvironmentObject var creatureVM: CreatureViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 40))
                        .foregroundColor(PixelColors.danger)
                    PixelText(text: "Choose Your Team", size: 18, color: .white)
                    PixelText(text: "Select 1-\(GameConstants.maxTeamSize) creatures for battle", size: 12, color: .gray)
                }
                .padding(.top, 20)

                if creatureVM.battleReady.isEmpty {
                    // No creatures available
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(PixelColors.gold)
                        PixelText(text: "No battle-ready creatures!", size: 14, color: .gray)
                        PixelText(text: "Complete tasks to hatch creatures first.", size: 12, color: .gray.opacity(0.7))
                    }
                    .padding(.vertical, 40)
                } else {
                    // Team selection
                    PixelCard {
                        VStack(spacing: 8) {
                            HStack {
                                PixelText(text: "YOUR TEAM", size: 12, color: .gray)
                                Spacer()
                                PixelText(text: "\(battleVM.selectedTeam.count)/\(GameConstants.maxTeamSize)", size: 12, color: PixelColors.accent)
                            }

                            if battleVM.selectedTeam.isEmpty {
                                PixelText(text: "Tap creatures below to select", size: 11, color: .gray.opacity(0.5))
                                    .padding(.vertical, 8)
                            } else {
                                HStack(spacing: 12) {
                                    ForEach(battleVM.selectedTeam) { creature in
                                        VStack(spacing: 4) {
                                            CreatureSpriteView(creature: creature, size: 48)
                                            PixelText(text: creature.name, size: 9, color: .white)
                                        }
                                        .onTapGesture {
                                            withAnimation { battleVM.toggleCreatureSelection(creature) }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // Available creatures grid
                    VStack(spacing: 8) {
                        HStack {
                            PixelText(text: "AVAILABLE", size: 12, color: .gray)
                            Spacer()
                        }

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(creatureVM.battleReady) { creature in
                                creatureSelectionCard(creature)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.2)) {
                                            battleVM.toggleCreatureSelection(creature)
                                        }
                                    }
                            }
                        }
                    }

                    // Battle mode selection
                    VStack(spacing: 8) {
                        HStack {
                            PixelText(text: "MODE", size: 12, color: .gray)
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            modeButton(title: "VS AI", icon: "cpu", mode: .local)
                            modeButton(title: "ONLINE", icon: "wifi", mode: .online)
                        }
                    }

                    // Start button
                    PixelButton(
                        title: battleVM.battleMode == .local ? "FIGHT!" : "FIND MATCH",
                        color: battleVM.selectedTeam.isEmpty ? .gray : PixelColors.danger,
                        textColor: .white
                    ) {
                        if battleVM.battleMode == .local {
                            battleVM.startLocalBattle()
                        } else {
                            battleVM.startMatchmaking()
                        }
                    }
                    .disabled(battleVM.selectedTeam.isEmpty)
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
    }

    private func creatureSelectionCard(_ creature: Creature) -> some View {
        let isSelected = battleVM.isSelected(creature)
        return PixelCard(borderColor: isSelected ? PixelColors.accent : creature.category.color.opacity(0.3)) {
            HStack(spacing: 8) {
                CreatureSpriteView(creature: creature, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    PixelText(text: creature.name, size: 11, color: .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 4) {
                        TypeBadge(category: creature.category, small: true)
                        PixelText(text: "Lv.\(creature.level)", size: 9, color: .gray)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(PixelColors.accent)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius)
                .stroke(isSelected ? PixelColors.accent : Color.clear, lineWidth: 2)
        )
    }

    private func modeButton(title: String, icon: String, mode: BattleMode) -> some View {
        let isActive = battleVM.battleMode == mode
        return Button(action: { battleVM.battleMode = mode }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? .black : .white)
                PixelText(text: title, size: 13, color: isActive ? .black : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isActive ? PixelColors.gold : PixelColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? PixelColors.gold : PixelColors.cardBorder, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
