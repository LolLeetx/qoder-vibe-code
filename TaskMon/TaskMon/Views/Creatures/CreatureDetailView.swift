import SwiftUI

struct CreatureDetailView: View {
    let creature: Creature
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PixelColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Hero sprite
                        ZStack {
                            Circle()
                                .fill(creature.category.color.opacity(0.1))
                                .frame(width: 120, height: 120)
                            CreatureSpriteView(creature: creature, size: 90)
                        }
                        .padding(.top, 8)

                        // Name + type
                        VStack(spacing: 6) {
                            PixelText(text: creature.name, size: 24, color: .white)
                            HStack(spacing: 8) {
                                TypeBadge(category: creature.category)
                                stageView
                            }
                        }

                        // Stats card
                        statsCard

                        // Evolution progress
                        if creature.stage < 3 {
                            evolutionCard
                        }

                        // Moves
                        movesCard
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .principal) {
                    PixelTitle(text: "DETAILS", color: creature.category.color)
                }
            }
        }
    }

    private var stageView: some View {
        HStack(spacing: 2) {
            PixelText(text: "Stage \(creature.stage)", size: 12, color: PixelColors.gold)
            ForEach(0..<creature.stage, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(PixelColors.gold)
            }
        }
    }

    private var statsCard: some View {
        PixelCard(borderColor: creature.category.color.opacity(0.4)) {
            VStack(spacing: 10) {
                HStack {
                    PixelText(text: "STATS", size: 12, color: .gray)
                    Spacer()
                    PixelText(text: "Lv. \(creature.level)", size: 12, color: PixelColors.gold)
                }

                statBar(label: "HP", value: creature.stats.maxHP, maxValue: 150, color: PixelColors.hpGreen)
                statBar(label: "ATK", value: creature.stats.attack, maxValue: 120, color: PixelColors.danger)
                statBar(label: "DEF", value: creature.stats.defense, maxValue: 120, color: PixelColors.xpBar)
                statBar(label: "SPD", value: creature.stats.speed, maxValue: 120, color: PixelColors.gold)
            }
        }
    }

    private func statBar(label: String, value: Int, maxValue: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            PixelText(text: label, size: 10, color: .gray)
                .frame(width: 30, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * min(1.0, Double(value) / Double(maxValue)))
                }
            }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            PixelText(text: "\(value)", size: 10, color: .white)
                .frame(width: 30, alignment: .leading)
        }
    }

    private var evolutionCard: some View {
        PixelCard(borderColor: PixelColors.gold.opacity(0.4)) {
            VStack(spacing: 8) {
                HStack {
                    PixelText(text: "EVOLUTION", size: 12, color: .gray)
                    Spacer()
                    PixelText(text: "\(creature.currentXP)/\(creature.nextEvolutionXP) XP", size: 10, color: PixelColors.gold)
                }

                ProgressView(value: creature.evolutionProgress)
                    .tint(PixelColors.gold)

                HStack {
                    PixelText(text: "Current: \(creature.name)", size: 10, color: .white)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    let nextNames = creature.category.creatureNames
                    let nextStage = min(creature.stage, nextNames.count - 1)
                    PixelText(text: "Next: \(nextNames[nextStage])", size: 10, color: PixelColors.gold)
                }
            }
        }
    }

    private var movesCard: some View {
        PixelCard(borderColor: creature.category.color.opacity(0.4)) {
            VStack(spacing: 10) {
                HStack {
                    PixelText(text: "MOVES", size: 12, color: .gray)
                    Spacer()
                    PixelText(text: "\(creature.moves.count)/4", size: 10, color: .gray)
                }

                ForEach(creature.moves) { move in
                    HStack {
                        TypeBadge(category: move.type, small: true)
                        PixelText(text: move.name, size: 12, color: .white)
                        Spacer()
                        PixelText(text: "PWR \(move.power)", size: 10, color: PixelColors.danger)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}
