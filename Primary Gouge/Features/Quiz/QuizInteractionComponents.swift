import SwiftUI

enum QuizAnswerVisualState: Hashable {
    case idle
    case correct
    case incorrect
    case correctReveal
    case subdued
}

enum QuizChoicePresentation {
    static func badgeText(for choice: QuizChoice, format: QuizQuestionFormat) -> String? {
        switch format {
        case .multipleChoice:
            return choice.id.uppercased()
        case .trueFalse:
            return nil
        }
    }
}

struct QuizAdaptivePromptView: View {
    let prompt: String
    let footer: String

    private let fontSizes: [CGFloat] = [30, 27, 24, 22, 20, 18]

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(fontSizes, id: \.self) { size in
                promptLayout(fontSize: size)
            }

            ScrollView(showsIndicators: true) {
                promptLayout(fontSize: 20)
            }
        }
    }

    private func promptLayout(fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prompt)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(footer)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct QuizAnswerButton: View {
    let label: String
    let badge: String?
    let state: QuizAnswerVisualState
    let isInteractive: Bool
    let fixedHeight: CGFloat?
    let action: () -> Void

    private let fontSizes: [CGFloat] = [17, 16, 15, 14, 13]

    var body: some View {
        Button {
            guard isInteractive else { return }
            action()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                if let badge {
                    ZStack {
                        Circle()
                            .fill(badgeFill)
                            .frame(width: 30, height: 30)

                        Text(badge)
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(badgeForeground)
                    }
                }

                adaptiveLabel

                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                } else if state == .incorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.danger)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, fixedHeight == nil ? 10 : 6)
            .frame(maxWidth: .infinity, minHeight: fixedHeight ?? 62)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(backgroundColor)
                    .overlay(borderOverlay)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var adaptiveLabel: some View {
        let height = max(24, (fixedHeight ?? 62) - 6)

        ViewThatFits(in: .vertical) {
            ForEach(fontSizes, id: \.self) { size in
                textLabel(fontSize: size)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView(showsIndicators: false) {
                textLabel(fontSize: 14)
            }
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
        }
    }

    private func textLabel(fontSize: CGFloat) -> some View {
        Text(label)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(labelColor)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:
            return AppTheme.surface.opacity(0.92)
        case .correct:
            return AppTheme.success.opacity(0.18)
        case .incorrect:
            return AppTheme.danger.opacity(0.18)
        case .correctReveal:
            return AppTheme.success.opacity(0.10)
        case .subdued:
            return AppTheme.surface.opacity(0.72)
        }
    }

    private var labelColor: Color {
        switch state {
        case .subdued:
            return AppTheme.textSecondary
        default:
            return AppTheme.textPrimary
        }
    }

    private var badgeFill: Color {
        switch state {
        case .correct:
            return AppTheme.success.opacity(0.24)
        case .incorrect:
            return AppTheme.danger.opacity(0.24)
        case .correctReveal:
            return AppTheme.success.opacity(0.18)
        case .subdued:
            return AppTheme.raisedSurface.opacity(0.8)
        case .idle:
            return AppTheme.raisedSurface
        }
    }

    private var badgeForeground: Color {
        switch state {
        case .correct:
            return AppTheme.success
        case .incorrect:
            return AppTheme.danger
        case .correctReveal:
            return AppTheme.success
        case .subdued:
            return AppTheme.textMuted
        case .idle:
            return AppTheme.textSecondary
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        switch state {
        case .correctReveal:
            shape.stroke(style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
                .foregroundStyle(AppTheme.success.opacity(0.85))
        case .correct:
            shape.stroke(AppTheme.success.opacity(0.8), lineWidth: 1.4)
        case .incorrect:
            shape.stroke(AppTheme.danger.opacity(0.8), lineWidth: 1.4)
        case .subdued:
            shape.stroke(AppTheme.cardStroke.opacity(0.7), lineWidth: 1)
        case .idle:
            shape.stroke(AppTheme.cardStroke, lineWidth: 1.1)
        }
    }
}
