import SwiftUI

struct EvolutionAnimationView: View {
    let creature: Creature
    let onDismiss: () -> Void

    @State private var showFlash = true
    @State private var showContent = false
    @State private var sparklePhase = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Flash effect
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .opacity(showFlash ? 0.8 : 0)
            }

            // Content
            if showContent {
                VStack(spacing: 24) {
                    // Sparkles
                    ZStack {
                        ForEach(0..<8, id: \.self) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: CGFloat.random(in: 12...24)))
                                .foregroundColor(creature.category.color)
                                .offset(
                                    x: sparklePhase ? CGFloat.random(in: -80...80) : 0,
                                    y: sparklePhase ? CGFloat.random(in: -80...80) : 0
                                )
                                .opacity(sparklePhase ? 0.8 : 0)
                                .rotationEffect(.degrees(Double(i) * 45))
                        }

                        CreatureSpriteView(creature: creature, size: 120)
                            .scaleEffect(showContent ? 1 : 0.3)
                    }

                    PixelText(text: creature.stage == 1 ? "NEW CREATURE!" : "EVOLVED!", size: 28, color: PixelColors.gold)

                    PixelText(text: creature.name, size: 20, color: .white)

                    HStack(spacing: 8) {
                        TypeBadge(category: creature.category)
                        HStack(spacing: 2) {
                            ForEach(0..<creature.stage, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(PixelColors.gold)
                            }
                        }
                    }

                    VStack(spacing: 4) {
                        PixelText(text: "HP \(creature.stats.maxHP)  ATK \(creature.stats.attack)", size: 12, color: .gray)
                        PixelText(text: "DEF \(creature.stats.defense)  SPD \(creature.stats.speed)", size: 12, color: .gray)
                    }

                    PixelButton(title: "AWESOME!", color: PixelColors.gold, textColor: .black) {
                        onDismiss()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            // Flash then reveal
            withAnimation(.easeOut(duration: 0.3)) {
                showFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showFlash = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showContent = true
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    sparklePhase = true
                }
            }
        }
    }
}
