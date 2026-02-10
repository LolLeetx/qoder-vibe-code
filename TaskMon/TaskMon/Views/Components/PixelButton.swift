import SwiftUI

struct PixelButton: View {
    let title: String
    var color: Color = PixelColors.accent
    var textColor: Color = .black
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            PixelText(text: title, size: 14, color: textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(color)
                .overlay(
                    Rectangle()
                        .stroke(color.opacity(0.5), lineWidth: GameConstants.pixelBorderWidth)
                )
                .shadow(color: color.opacity(0.3), radius: 0, x: 3, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct PixelCard<Content: View>: View {
    var borderColor: Color = PixelColors.cardBorder
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .background(PixelColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius)
                    .stroke(borderColor, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius))
    }
}
