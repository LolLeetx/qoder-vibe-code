import SwiftUI

struct PixelText: View {
    let text: String
    var size: CGFloat = 16
    var color: Color = .white

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .monospaced))
            .foregroundColor(color)
    }
}

struct PixelTitle: View {
    let text: String
    var color: Color = .white

    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .black, design: .monospaced))
            .foregroundColor(color)
            .tracking(2)
    }
}
