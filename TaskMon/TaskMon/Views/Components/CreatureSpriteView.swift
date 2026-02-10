import SwiftUI

struct CreatureSpriteView: View {
    let creature: Creature
    var size: CGFloat = 80

    var body: some View {
        Image(creature.spriteName)
            .resizable()
            .interpolation(.none) // keep pixel art crisp
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .background(
                // Fallback if image not found
                FallbackCreatureView(creature: creature, size: size)
            )
    }
}

struct FallbackCreatureView: View {
    let creature: Creature
    var size: CGFloat = 80

    private var iconName: String {
        switch creature.category {
        case .work: return creature.stage >= 3 ? "gearshape.2.fill" : creature.stage >= 2 ? "wrench.and.screwdriver.fill" : "hammer.fill"
        case .health: return creature.stage >= 3 ? "tree.fill" : creature.stage >= 2 ? "leaf.fill" : "heart.fill"
        case .learning: return creature.stage >= 3 ? "graduationcap.fill" : creature.stage >= 2 ? "books.vertical.fill" : "book.fill"
        case .creative: return creature.stage >= 3 ? "flame.fill" : creature.stage >= 2 ? "paintpalette.fill" : "paintbrush.fill"
        case .personal: return creature.stage >= 3 ? "sparkles" : creature.stage >= 2 ? "star.fill" : "moon.fill"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(creature.category.color.opacity(0.2))
                .frame(width: size, height: size)

            Circle()
                .stroke(creature.category.color.opacity(0.5), lineWidth: 2)
                .frame(width: size, height: size)

            Image(systemName: iconName)
                .font(.system(size: size * 0.4))
                .foregroundColor(creature.category.color)
        }
        .frame(width: size, height: size)
    }
}
