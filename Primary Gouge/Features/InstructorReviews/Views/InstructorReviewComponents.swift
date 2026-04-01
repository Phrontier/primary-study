import SwiftUI

enum InstructorRatingBadgeStyle {
    case roster
    case individual
}

struct InstructorRatingBadge: View {
    let title: String
    let label: String
    let subtitle: String
    let score: Int
    let style: InstructorRatingBadgeStyle

    private var accent: Color {
        InstructorRatingScale.color(for: score)
    }

    private var subtitleFont: Font {
        switch style {
        case .roster:
            return .system(.caption, design: .rounded, weight: .bold)
        case .individual:
            return .system(.caption, design: .rounded, weight: .medium)
        }
    }

    private var subtitleColor: Color {
        switch style {
        case .roster:
            return AppTheme.prominentText(accent)
        case .individual:
            return AppTheme.textSecondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.prominentText(accent))
                .tracking(0.6)

            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)

            Text(subtitle)
                .font(subtitleFont)
                .foregroundStyle(subtitleColor)
                .padding(.horizontal, style == .roster ? 8 : 0)
                .padding(.vertical, style == .roster ? 5 : 0)
                .background {
                    if style == .roster {
                        Capsule()
                            .fill(AppTheme.badgeFill(accent))
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.badgeStroke(accent), lineWidth: 1)
                            )
                    }
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 108, maxHeight: 108, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.elevatedSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 16)
                .padding(.leading, 1)
        }
    }
}

struct InstructorAggregateCard: View {
    let title: String
    let label: String
    let average: Double

    private var roundedScore: Int {
        InstructorRatingScale.roundedScore(for: average)
    }

    private var accent: Color {
        InstructorRatingScale.color(for: roundedScore)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppTheme.prominentText(accent))
                        .frame(width: 8, height: 8)

                    Text(title.uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.prominentText(accent))
                        .tracking(0.6)
                }

                Spacer(minLength: 0)

                Text(label)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)

                Text(InstructorRatingScale.formatOutOfSeven(average: average))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.prominentText(accent))

                Capsule()
                    .fill(accent)
                    .frame(width: 56, height: 4)
                    .opacity(0.95)
            }
            .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        }
    }
}

struct InstructorReviewCard: View {
    let review: InstructorReview

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let eventName = review.eventName {
                            Text(eventName)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        HStack(spacing: 8) {
                            Text(review.eventKind.displayName.uppercased())
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.prominentText(review.eventKind.domainColor))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.badgeFill(review.eventKind.domainColor))
                                        .overlay(
                                            Capsule()
                                                .stroke(AppTheme.badgeStroke(review.eventKind.domainColor), lineWidth: 1)
                                        )
                                )

                            Text(review.submittedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(.footnote, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Spacer(minLength: 12)

                    statusPill
                }

                HStack(spacing: 12) {
                    InstructorRatingBadge(
                        title: "Chill Factor",
                        label: InstructorRatingScale.label(for: review.chillScore, category: .chillFactor),
                        subtitle: InstructorRatingScale.formatSpacedOutOfSeven(score: review.chillScore, includeAverageSuffix: true),
                        score: review.chillScore,
                        style: .individual
                    )
                    InstructorRatingBadge(
                        title: "Grading Style",
                        label: InstructorRatingScale.label(for: review.gradingScore, category: .gradingStyle),
                        subtitle: InstructorRatingScale.formatSpacedOutOfSeven(score: review.gradingScore, includeAverageSuffix: true),
                        score: review.gradingScore,
                        style: .individual
                    )
                }

                Text(review.reviewText)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var statusPill: some View {
        if review.status != .approved {
            Text(review.status.displayName)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.prominentText(review.status.statusColor))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.badgeFill(review.status.statusColor))
                        .overlay(
                            Capsule().stroke(AppTheme.badgeStroke(review.status.statusColor), lineWidth: 1)
                        )
                )
        }
    }
}

struct InstructorSummaryCard: View {
    let instructor: Instructor

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(instructor.name)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 8) {
                            Text(instructor.squadron.displayName)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)

                            ForEach(instructor.capabilityBadges, id: \.self) { capability in
                                InstructorCapabilityBadge(capability: capability)
                            }
                        }
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(instructor.publishedReviewCount)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.prominentText(AppTheme.domainColor(.instructors)))

                        Text(instructor.reviewCountLabel)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textMuted)
                            .tracking(0.5)
                    }
                }

                HStack(spacing: 12) {
                    InstructorRatingBadge(
                        title: "Chill Factor",
                        label: instructor.chillLabel,
                        subtitle: instructor.chillAverageOutOfSevenText,
                        score: instructor.chillRoundedScore,
                        style: .roster
                    )
                    InstructorRatingBadge(
                        title: "Grading Style",
                        label: instructor.gradingLabel,
                        subtitle: instructor.gradingAverageOutOfSevenText,
                        score: instructor.gradingRoundedScore,
                        style: .roster
                    )
                }
            }
        }
    }
}

struct InstructorCapabilityBadge: View {
    let capability: InstructorReviewEventKind

    var body: some View {
        Text(capability.pluralDisplayName.uppercased())
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.prominentText(capability.domainColor))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(AppTheme.badgeFill(capability.domainColor))
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.badgeStroke(capability.domainColor), lineWidth: 1)
                    )
            )
    }
}

struct InstructorPillSelector<Option: Identifiable & Hashable>: View {
    let options: [Option]
    let selected: Option
    let title: (Option) -> String
    let accent: (Option) -> Color
    let action: (Option) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options) { option in
                    Button {
                        action(option)
                    } label: {
                        Text(title(option))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(selected == option ? AppTheme.prominentText(accent(option)) : AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(
                                Capsule()
                                    .fill(selected == option ? AppTheme.badgeFill(accent(option)) : AppTheme.elevatedSurface)
                                    .overlay(
                                        Capsule()
                                            .stroke(selected == option ? AppTheme.badgeStroke(accent(option)) : AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct InstructorAdaptiveSelector<Option: Identifiable & Hashable>: View {
    let options: [Option]
    let selected: Option
    let title: (Option) -> String
    let accent: (Option) -> Color
    let menuTitle: String
    let action: (Option) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            singleLineSelector
                .fixedSize(horizontal: true, vertical: false)

            dropdownSelector
        }
    }

    private var singleLineSelector: some View {
        HStack(spacing: 10) {
            ForEach(options) { option in
                Button {
                    action(option)
                } label: {
                    Text(title(option))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(selected == option ? AppTheme.prominentText(accent(option)) : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(selected == option ? AppTheme.badgeFill(accent(option)) : AppTheme.elevatedSurface)
                                .overlay(
                                    Capsule()
                                        .stroke(selected == option ? AppTheme.badgeStroke(accent(option)) : AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dropdownSelector: some View {
        Menu {
            ForEach(options) { option in
                Button {
                    action(option)
                } label: {
                    Label(title(option), systemImage: selected == option ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(menuTitle.uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                        .tracking(0.6)

                    Text(title(selected))
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.iconTint(accent(selected)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.elevatedSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.badgeStroke(accent(selected)), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InstructorSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.elevatedSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                )
        )
    }
}

struct InstructorMenuPicker: View {
    let title: String
    let placeholder: String
    let selection: String?
    let detail: String?
    let accent: Color
    let action: () -> Void

    init(
        title: String,
        placeholder: String,
        selection: String?,
        detail: String? = nil,
        accent: Color,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.selection = selection
        self.detail = detail
        self.accent = accent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.textMuted)
                    .tracking(0.6)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selection ?? placeholder)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(selection == nil ? AppTheme.textSecondary : AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)

                        if let detail, selection != nil {
                            Text(detail)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(.top, 2)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.elevatedSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct InstructorTextFieldCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)
                .tracking(0.6)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.elevatedSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                        )
                )
        }
    }
}

struct InstructorSelectionSheet<Option: Identifiable, RowContent: View>: View where Option.ID: Hashable {
    let title: String
    let subtitle: String
    let options: [Option]
    let selectedID: Option.ID?
    let onSelect: (Option) -> Void
    @ViewBuilder let rowContent: (Option) -> RowContent

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(subtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)

                        ForEach(options) { option in
                            Button {
                                onSelect(option)
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    rowContent(option)

                                    Spacer(minLength: 8)

                                    if selectedID == option.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(AppTheme.elevatedSurface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .stroke(selectedID == option.id ? AppTheme.accent.opacity(0.32) : AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
            .scrollActivatedNavigationChrome(title: title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                EmptyView()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct InstructorPrimaryButton: View {
    let title: String
    let icon: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(.headline, design: .rounded, weight: .bold))

                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        enabled
                            ? AppTheme.accentGradient
                            : LinearGradient(
                                colors: [AppTheme.raisedSurface, AppTheme.elevatedSurface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.66)
    }
}
