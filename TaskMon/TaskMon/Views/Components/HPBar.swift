import SwiftUI

struct HPBar: View {
    let currentHP: Int
    let maxHP: Int
    var height: CGFloat = 12
    var showLabel: Bool = true

    private var fraction: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    private var barColor: Color {
        if fraction > 0.5 { return PixelColors.hpGreen }
        if fraction > 0.25 { return PixelColors.hpYellow }
        return PixelColors.hpRed
    }

    var body: some View {
        VStack(spacing: 2) {
            if showLabel {
                HStack {
                    PixelText(text: "HP", size: 10, color: .gray)
                    Spacer()
                    PixelText(text: "\(currentHP)/\(maxHP)", size: 10, color: .gray)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(height: height)

                    Rectangle()
                        .fill(barColor)
                        .frame(width: max(0, geo.size.width * fraction), height: height)
                        .animation(.easeInOut(duration: 0.5), value: currentHP)
                }
                .overlay(
                    Rectangle()
                        .stroke(PixelColors.cardBorder, lineWidth: 1)
                )
            }
            .frame(height: height)
        }
    }
}

struct XPProgressBar: View {
    let currentXP: Int
    let nextMilestone: Int
    let category: TaskCategory

    private var fraction: Double {
        guard nextMilestone > 0 else { return 1.0 }
        return min(1.0, Double(currentXP) / Double(nextMilestone))
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.system(size: 12))
                PixelText(text: category.displayName, size: 11, color: category.color)
                Spacer()
                PixelText(text: "\(currentXP) XP", size: 11, color: .white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))

                    Rectangle()
                        .fill(category.color.opacity(0.8))
                        .frame(width: max(0, geo.size.width * fraction))
                        .animation(.easeInOut(duration: 0.4), value: currentXP)
                }
                .overlay(
                    Rectangle()
                        .stroke(category.color.opacity(0.3), lineWidth: 1)
                )
            }
            .frame(height: 8)
        }
    }
}

struct TypeBadge: View {
    let category: TaskCategory
    var small: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: category.icon)
                .font(.system(size: small ? 8 : 10))
            if !small {
                Text(category.displayName)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, small ? 4 : 6)
        .padding(.vertical, 2)
        .background(category.color.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
