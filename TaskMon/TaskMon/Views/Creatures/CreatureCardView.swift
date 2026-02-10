import SwiftUI

struct CreatureCardView: View {
    let creature: Creature

    var body: some View {
        PixelCard(borderColor: creature.category.color.opacity(0.5)) {
            VStack(spacing: 4) {
                // Sprite
                CreatureSpriteView(creature: creature, size: 48)

                // Name
                PixelText(text: creature.name, size: 10, color: .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Type + Stage
                HStack(spacing: 2) {
                    TypeBadge(category: creature.category, small: true)
                    stageStars
                }

                // Mini stats
                HStack(spacing: 4) {
                    statIcon("heart.fill", value: creature.stats.maxHP, color: PixelColors.hpGreen)
                    statIcon("bolt.fill", value: creature.stats.attack, color: PixelColors.danger)
                }
            }
        }
    }

    private var stageStars: some View {
        HStack(spacing: 1) {
            ForEach(0..<creature.stage, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 7))
                    .foregroundColor(PixelColors.gold)
            }
        }
    }

    private func statIcon(_ icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
