import Foundation
import SwiftUI

enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case work
    case health
    case learning
    case creative
    case personal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .health: return "Health"
        case .learning: return "Learning"
        case .creative: return "Creative"
        case .personal: return "Personal"
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .creative: return "paintbrush.fill"
        case .personal: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: return Color(red: 0.9, green: 0.3, blue: 0.2)
        case .health: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .learning: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .creative: return Color(red: 0.8, green: 0.4, blue: 0.9)
        case .personal: return Color(red: 0.9, green: 0.7, blue: 0.2)
        }
    }

    var creatureBaseName: String {
        switch self {
        case .work: return "Forgebot"
        case .health: return "Vitaleaf"
        case .learning: return "Wisowl"
        case .creative: return "Artflame"
        case .personal: return "Starbit"
        }
    }

    var creatureNames: [String] {
        switch self {
        case .work: return ["Forgebot", "Forgeron", "Forgetitan"]
        case .health: return ["Vitaleaf", "Vitabloom", "Vitatree"]
        case .learning: return ["Wisowl", "Wisphoenix", "Wislord"]
        case .creative: return ["Artflame", "Artblaze", "Artinferno"]
        case .personal: return ["Starbit", "Starnova", "Starcosmos"]
        }
    }

    /// Type effectiveness: what this type is strong against
    var strongAgainst: TaskCategory {
        switch self {
        case .work: return .learning
        case .learning: return .creative
        case .creative: return .health
        case .health: return .work
        case .personal: return .personal // neutral
        }
    }

    /// Type effectiveness: what this type is weak against
    var weakAgainst: TaskCategory {
        switch self {
        case .work: return .health
        case .health: return .creative
        case .creative: return .learning
        case .learning: return .work
        case .personal: return .personal // neutral
        }
    }
}
