import SwiftUI

struct MatchmakingView: View {
    @EnvironmentObject var battleVM: BattleViewModel
    @State private var dotCount = 0
    @State private var pulseScale: CGFloat = 1.0

    private var formattedTime: String {
        let mins = battleVM.matchmakingSeconds / 60
        let secs = battleVM.matchmakingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var dots: String {
        String(repeating: ".", count: (dotCount % 3) + 1)
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Animated radar/search icon
            ZStack {
                // Outer pulse rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(PixelColors.accent.opacity(0.15), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i) * 40, height: 120 + CGFloat(i) * 40)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - Double(pulseScale) * 0.8)
                }

                Circle()
                    .fill(PixelColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(PixelColors.accent.opacity(0.4), lineWidth: 2)
                    .frame(width: 100, height: 100)

                Image(systemName: "wifi")
                    .font(.system(size: 36))
                    .foregroundColor(PixelColors.accent)
                    .rotationEffect(.degrees(pulseScale > 1.0 ? 5 : -5))
            }

            // Status text
            VStack(spacing: 8) {
                PixelText(text: "Searching for opponent\(dots)", size: 16, color: .white)
                PixelText(text: formattedTime, size: 28, color: PixelColors.accent)
            }

            // Team preview
            PixelCard(borderColor: PixelColors.accent.opacity(0.3)) {
                VStack(spacing: 8) {
                    PixelText(text: "YOUR TEAM", size: 10, color: .gray)
                    HStack(spacing: 16) {
                        ForEach(battleVM.selectedTeam) { creature in
                            VStack(spacing: 4) {
                                CreatureSpriteView(creature: creature, size: 44)
                                PixelText(text: creature.name, size: 9, color: .white)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Cancel button
            PixelButton(title: "CANCEL", color: PixelColors.danger, textColor: .white) {
                battleVM.cancelMatchmaking()
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Dot animation
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            dotCount += 1
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
}
