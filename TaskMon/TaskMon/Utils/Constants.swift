import Foundation
import SwiftUI

enum GameConstants {
    // XP Rewards
    static let xpEasy = 10
    static let xpMedium = 25
    static let xpHard = 50

    // Evolution Thresholds (category XP)
    static let stage1Threshold = 100
    static let stage2Threshold = 500
    static let stage3Threshold = 1000

    // Battle
    static let maxTeamSize = 3
    static let turnTimeout: TimeInterval = 30

    // UI
    static let pixelCornerRadius: CGFloat = 4
    static let cardCornerRadius: CGFloat = 8
    static let pixelBorderWidth: CGFloat = 3
    static let animationDuration: Double = 0.3
}

enum PixelColors {
    static let background = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let cardBackground = Color(red: 0.14, green: 0.14, blue: 0.2)
    static let cardBorder = Color(red: 0.3, green: 0.3, blue: 0.4)
    static let accent = Color(red: 0.4, green: 0.8, blue: 1.0)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let danger = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let success = Color(red: 0.3, green: 0.9, blue: 0.4)
    static let xpBar = Color(red: 0.3, green: 0.6, blue: 1.0)

    static let hpGreen = Color(red: 0.2, green: 0.9, blue: 0.3)
    static let hpYellow = Color(red: 0.9, green: 0.8, blue: 0.2)
    static let hpRed = Color(red: 0.9, green: 0.2, blue: 0.2)
}
