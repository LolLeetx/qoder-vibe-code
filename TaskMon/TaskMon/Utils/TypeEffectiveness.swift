import Foundation

enum TypeEffectiveness {
    static let superEffective: Double = 1.5
    static let neutral: Double = 1.0
    static let notEffective: Double = 0.67

    /// Returns the damage multiplier for attacking type vs defending type
    /// Chart: Work > Learning > Creative > Health > Work
    /// Personal is neutral against everything
    static func multiplier(attacking: TaskCategory, defending: TaskCategory) -> Double {
        if attacking == .personal || defending == .personal {
            return neutral
        }
        if attacking.strongAgainst == defending {
            return superEffective
        }
        if attacking.weakAgainst == defending {
            return notEffective
        }
        return neutral
    }

    static func effectivenessText(attacking: TaskCategory, defending: TaskCategory) -> String? {
        let mult = multiplier(attacking: attacking, defending: defending)
        if mult > neutral {
            return "Super effective!"
        } else if mult < neutral {
            return "Not very effective..."
        }
        return nil
    }
}
