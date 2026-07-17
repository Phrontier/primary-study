import SwiftUI

struct CharacterRequirement: Hashable {
    let characterCount: Int
    let minimum: Int

    init(text: String, minimum: Int) {
        self.characterCount = text.trimmingCharacters(in: .whitespacesAndNewlines).count
        self.minimum = minimum
    }

    var remainingCharacters: Int {
        max(0, minimum - characterCount)
    }

    var isMinimumMet: Bool {
        remainingCharacters == 0
    }

    var statusText: String {
        isMinimumMet ? "Minimum met" : "\(remainingCharacters) characters to go"
    }
}

struct CharacterGuidance: View {
    let text: String
    let minimum: Int
    let identifier: String

    private var requirement: CharacterRequirement {
        CharacterRequirement(text: text, minimum: minimum)
    }

    private var accessibilityValueText: String {
        let countText = "\(requirement.characterCount) characters"
        return requirement.isMinimumMet
            ? "\(countText). Minimum met."
            : "\(countText). \(requirement.remainingCharacters) characters to go."
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(requirement.statusText)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(requirement.isMinimumMet ? AppTheme.success : AppTheme.warning)

            Spacer(minLength: 8)

            Text("\(requirement.characterCount) chars")
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Character requirement")
        .accessibilityValue(accessibilityValueText)
        .accessibilityIdentifier(identifier)
    }
}
