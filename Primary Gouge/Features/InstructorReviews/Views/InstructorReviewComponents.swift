import SwiftUI

enum InstructorGougeReportTarget: Identifiable, Hashable {
    case instructor(Instructor)
    case review(InstructorReview)

    var id: String {
        switch self {
        case .instructor(let instructor):
            return "instructor-\(instructor.id)"
        case .review(let review):
            return "review-\(review.id)"
        }
    }

    var title: String {
        switch self {
        case .instructor:
            return "Report Instructor Info"
        case .review:
            return "Report Review"
        }
    }

    var subtitle: String {
        switch self {
        case .instructor(let instructor):
            return "Flag incorrect name, squadron, or mixed instructor info for \(instructor.name)."
        case .review:
            return "Flag a review that is inaccurate, inappropriate, or should be looked at again."
        }
    }

    var targetKind: InstructorGougeReportTargetKind {
        switch self {
        case .instructor:
            return .instructor
        case .review:
            return .review
        }
    }

    var instructorID: String {
        switch self {
        case .instructor(let instructor):
            return instructor.id
        case .review(let review):
            return review.instructorID
        }
    }

    var reviewID: String? {
        switch self {
        case .instructor:
            return nil
        case .review(let review):
            return review.id
        }
    }

    var instructorName: String {
        switch self {
        case .instructor(let instructor):
            return instructor.name
        case .review(let review):
            return review.instructorName
        }
    }

    var squadron: Squadron {
        switch self {
        case .instructor(let instructor):
            return instructor.squadron
        case .review(let review):
            return review.squadron
        }
    }

    var eventName: String? {
        switch self {
        case .instructor:
            return nil
        case .review(let review):
            return review.eventName
        }
    }

    var eventKind: InstructorReviewEventKind? {
        switch self {
        case .instructor:
            return nil
        case .review(let review):
            return review.eventKind
        }
    }

    var reviewText: String? {
        switch self {
        case .instructor:
            return nil
        case .review(let review):
            return review.reviewText
        }
    }
}

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
            return .system(.caption, design: .rounded, weight: .bold)
        }
    }

    private var subtitleColor: Color {
        switch style {
        case .roster:
            return AppTheme.prominentText(accent)
        case .individual:
            return AppTheme.prominentText(accent)
        }
    }

    private var scorePillHorizontalPadding: CGFloat {
        switch style {
        case .roster:
            return 10
        case .individual:
            return 8
        }
    }

    private var scorePillVerticalPadding: CGFloat {
        switch style {
        case .roster:
            return 6
        case .individual:
            return 5
        }
    }

    private var contentVerticalPadding: CGFloat {
        switch style {
        case .roster:
            return 12
        case .individual:
            return 14
        }
    }

    private var titleView: some View {
        Text(title.uppercased())
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.prominentText(accent))
            .tracking(style == .roster ? 0.5 : 0.6)
    }

    private var subtitlePill: some View {
        Text(subtitle)
            .font(subtitleFont)
            .foregroundStyle(subtitleColor)
            .padding(.horizontal, scorePillHorizontalPadding)
            .padding(.vertical, scorePillVerticalPadding)
            .background {
                Capsule()
                    .fill(AppTheme.badgeFill(accent).opacity(style == .roster ? 0.8 : 1))
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.badgeStroke(accent), lineWidth: 1)
                    )
            }
    }

    private var labelView: some View {
        Text(label)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var verticalAccent: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(accent)
            .frame(width: style == .roster ? 4 : 4)
            .opacity(style == .roster ? 0.82 : 1)
            .padding(.vertical, style == .roster ? 20 : 16)
            .padding(.leading, 1)
    }

    private var rosterBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleView
                .padding(.top, 3)

            Spacer()
                .frame(height: 6)

            labelView
                .frame(height: 38, alignment: .center)

            Spacer()
                .frame(height: 7)

            subtitlePill

            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var individualBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleView

            Spacer()
                .frame(height: 6)

            labelView
                .frame(height: 38, alignment: .center)

            Spacer()
                .frame(height: 7)

            subtitlePill

            Spacer(minLength: 4)
        }
    }

    private var cardHeight: CGFloat {
        switch style {
        case .roster:
            return 104
        case .individual:
            return 108
        }
    }

    var body: some View {
        Group {
            switch style {
            case .roster:
                rosterBody
            case .individual:
                individualBody
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, contentVerticalPadding)
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.elevatedSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            verticalAccent
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

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(InstructorRatingScale.format(average: InstructorRatingScale.tenScaleValue(for: average))) / 10")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.prominentText(accent))

                    Text("avg")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                }

                Capsule()
                    .fill(accent)
                    .frame(width: 56, height: 4)
                    .opacity(0.95)
            }
            .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        }
    }
}

struct InstructorGougeReportSheet: View {
    let target: InstructorGougeReportTarget
    let onSubmitted: () -> Void

    private let minimumCommentCount = 15
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @State private var selectedInstructorReason: InstructorInfoReportReason?
    @State private var note = ""
    @State private var errorMessage: String?

    private var selectedReasonTitle: String? {
        switch target {
        case .instructor:
            return selectedInstructorReason?.title
        case .review:
            return "Review Report"
        }
    }

    private var trimmedComment: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var remainingCommentCharacters: Int {
        max(0, minimumCommentCount - trimmedComment.count)
    }

    private var canSubmit: Bool {
        selectedReasonTitle != nil && remainingCommentCharacters == 0
    }

    var body: some View {
        AppScrollScreen(bottomPadding: 36) {
            VStack(alignment: .leading, spacing: 8) {
                Text(target.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(target.subtitle)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    reportTargetSummary

                    if case .instructor = target {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reason")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.textMuted)
                                .tracking(0.6)

                            ForEach(InstructorInfoReportReason.allCases) { reason in
                                reasonRow(
                                    title: reason.title,
                                    selected: selectedInstructorReason == reason
                                ) {
                                    selectedInstructorReason = reason
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Comment")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textMuted)
                            .tracking(0.6)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppTheme.elevatedSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                )

                            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Add any detail that would help moderation understand what looks wrong.")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                            }

                            TextEditor(text: $note)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                        }
                        .frame(minHeight: 120)

                        HStack {
                            Text(
                                remainingCommentCharacters == 0
                                    ? "Minimum met"
                                    : "\(remainingCommentCharacters) characters to go"
                            )
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(remainingCommentCharacters == 0 ? AppTheme.success : AppTheme.warning)

                            Spacer()

                            Text("\(trimmedComment.count) chars")
                                .font(.system(.footnote, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.warning)
                    .padding(.horizontal, 6)
            }

            InstructorPrimaryButton(
                title: "Send Report",
                icon: "exclamationmark.bubble.fill",
                enabled: canSubmit
            ) {
                submitReport()
            }
        }
        .detailNavigationChrome(title: "Report Gouge")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var reportTargetSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(target.instructorName)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 8) {
                Text(target.squadron.displayName)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                if let eventName = target.eventName, let eventKind = target.eventKind {
                    Text(eventKind.displayName.uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.prominentText(eventKind.domainColor))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.badgeFill(eventKind.domainColor))
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.badgeStroke(eventKind.domainColor), lineWidth: 1)
                                )
                        )

                    Text(eventName)
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func reasonRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(reasonIndicatorColor(selected: selected))
                    .frame(width: 10, height: 10)

                Text(title)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer(minLength: 8)

                trailingSelectionIndicator(selected: selected)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.elevatedSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(reasonStrokeColor(selected: selected), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func reasonIndicatorColor(selected: Bool) -> Color {
        switch target {
        case .instructor:
            return selected ? AppTheme.danger : AppTheme.textMuted.opacity(0.5)
        case .review:
            return AppTheme.textMuted.opacity(0.5)
        }
    }

    private func reasonStrokeColor(selected: Bool) -> Color {
        switch target {
        case .instructor:
            return selected ? AppTheme.badgeStroke(AppTheme.danger) : AppTheme.cardStroke.opacity(0.9)
        case .review:
            return AppTheme.cardStroke.opacity(0.9)
        }
    }

    @ViewBuilder
    private func trailingSelectionIndicator(selected: Bool) -> some View {
        switch target {
        case .instructor:
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
            } else {
                Color.clear
                    .frame(width: 16, height: 16)
            }
        case .review:
            Color.clear
                .frame(width: 16, height: 16)
        }
    }

    private func submitReport() {
        guard let selectedReasonTitle else { return }
        guard remainingCommentCharacters == 0 else {
            errorMessage = "Comment must be at least \(minimumCommentCount) characters."
            return
        }

        do {
            try reviewStore.submitReport(
                InstructorGougeReportSubmission(
                    targetKind: target.targetKind,
                    instructorID: target.instructorID,
                    reviewID: target.reviewID,
                    instructorName: target.instructorName,
                    squadron: target.squadron,
                    eventName: target.eventName,
                    eventKind: target.eventKind,
                    reviewText: target.reviewText,
                    reasonTitle: selectedReasonTitle,
                    note: trimmedComment
                )
            )
            onSubmitted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct InstructorReviewCard: View {
    let review: InstructorReview
    let onReport: (() -> Void)?

    init(review: InstructorReview, onReport: (() -> Void)? = nil) {
        self.review = review
        self.onReport = onReport
    }

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

                    HStack(spacing: 8) {
                        if let onReport {
                            ReportActionButton(action: onReport)
                        }

                        statusPill
                    }
                }

                HStack(spacing: 12) {
                    InstructorRatingBadge(
                        title: "Chill Factor",
                        label: InstructorRatingScale.label(for: review.chillScore, category: .chillFactor),
                        subtitle: InstructorRatingScale.formatOutOfTen(score: review.chillScore),
                        score: review.chillScore,
                        style: .individual
                    )
                    InstructorRatingBadge(
                        title: "Grading Style",
                        label: InstructorRatingScale.label(for: review.gradingScore, category: .gradingStyle),
                        subtitle: InstructorRatingScale.formatOutOfTen(score: review.gradingScore),
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
                    Text(instructor.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 12)

                    Text(instructor.squadron.displayName)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.96))
                }

                HStack(spacing: 12) {
                    InstructorRatingBadge(
                        title: "Chill Factor",
                        label: instructor.chillLabel,
                        subtitle: instructor.chillAverageOutOfTenText,
                        score: instructor.chillRoundedScore,
                        style: .roster
                    )
                    InstructorRatingBadge(
                        title: "Grading Style",
                        label: instructor.gradingLabel,
                        subtitle: instructor.gradingAverageOutOfTenText,
                        score: instructor.gradingRoundedScore,
                        style: .roster
                    )
                }

                HStack(spacing: 10) {
                    Text(instructor.reviewCountText)
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer(minLength: 8)

                    ForEach(instructor.capabilityBadges, id: \.self) { capability in
                        InstructorCapabilityBadge(capability: capability)
                    }
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
    let enabled: Bool
    let action: () -> Void

    init(
        title: String,
        placeholder: String,
        selection: String?,
        detail: String? = nil,
        accent: Color,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.selection = selection
        self.detail = detail
        self.accent = accent
        self.enabled = enabled
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
                        } else if !enabled {
                            Text(placeholder)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(enabled ? accent : AppTheme.textMuted)
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
                            .stroke((enabled ? AppTheme.cardStroke : AppTheme.cardStroke.opacity(0.7)), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.72)
    }
}

struct InstructorTextFieldCard: View {
    let title: String
    let placeholder: String
    let detail: String?
    let enabled: Bool
    @Binding var text: String

    init(
        title: String,
        placeholder: String,
        detail: String? = nil,
        enabled: Bool = true,
        text: Binding<String>
    ) {
        self.title = title
        self.placeholder = placeholder
        self.detail = detail
        self.enabled = enabled
        self._text = text
    }

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
                                .stroke((enabled ? AppTheme.cardStroke.opacity(0.9) : AppTheme.cardStroke.opacity(0.65)), lineWidth: 1)
                        )
                )
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.72)

            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

struct InstructorSelectionSheet<Option: Identifiable, RowContent: View>: View where Option.ID: Hashable {
    let title: String
    let subtitle: String
    let options: [Option]
    let selectedID: Option.ID?
    let accent: (Option) -> Color
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
                                            .foregroundStyle(accent(option))
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
                                                .stroke(selectedID == option.id ? AppTheme.badgeStroke(accent(option)) : AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
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
            .detailNavigationChrome(title: title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct InstructorSearchableSelectionSheet<Option: Identifiable, RowContent: View>: View where Option.ID: Hashable {
    let title: String
    let subtitle: String
    let searchPlaceholder: String
    let emptyMessage: String
    let options: [Option]
    let selectedID: Option.ID?
    let searchableText: (Option) -> String
    let accent: (Option) -> Color
    let onSelect: (Option) -> Void
    @ViewBuilder let rowContent: (Option) -> RowContent

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredOptions: [Option] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return options }

        return options.filter {
            searchableText($0)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .localizedStandardContains(query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    InstructorSearchField(
                        placeholder: searchPlaceholder,
                        text: $searchText
                    )
                    .padding(.horizontal, 20)

                    if filteredOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No matches")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(emptyMessage)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer(minLength: 0)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(filteredOptions) { option in
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
                                                    .foregroundStyle(accent(option))
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
                                                        .stroke(selectedID == option.id ? AppTheme.badgeStroke(accent(option)) : AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .detailNavigationChrome(title: title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
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
