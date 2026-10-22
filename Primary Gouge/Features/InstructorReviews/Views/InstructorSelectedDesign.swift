import SwiftUI

struct SelectedInstructorScores: View {
    let chill: Double
    let grading: Double
    var compact = false
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 20) { score(chill, .chillFactor); score(grading, .gradingStyle) }
        } else {
            HStack(alignment: .top, spacing: 20) {
                score(chill, .chillFactor).frame(maxWidth: .infinity, alignment: .leading)
                score(grading, .gradingStyle).frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20).overlay(alignment: .leading) { Rectangle().fill(StudyDesign.line).frame(width: 1) }
            }
        }
    }
    private func score(_ average: Double, _ category: InstructorRatingCategory) -> some View {
        let available = average.isFinite && average > 0
        let band = available ? InstructorRatingScale.roundedScore(for: average) : 0
        let color = available ? InstructorRatingScale.color(for: band) : StudyDesign.secondary
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(available ? InstructorRatingScale.format(average: InstructorRatingScale.tenScaleValue(for: average)) : "—")
                    .selectedText(compact ? 21 : 26, line: compact ? 25 : 31, weight: .bold).foregroundStyle(color)
                Text("/ 10").selectedText(11).foregroundStyle(StudyDesign.secondary)
            }
            Text(category.displayName).selectedText(11).foregroundStyle(StudyDesign.secondary)
            HStack(spacing: 3) {
                ForEach(1...7, id: \.self) { segment in
                    Capsule().fill(segment <= band ? color : StudyDesign.cardLine).frame(height: 4)
                }
            }.frame(maxWidth: 120).padding(.vertical, 3).accessibilityHidden(true)
            Text(available ? InstructorRatingScale.label(for: band, category: category) : "No reviews yet").selectedText(10, line: 15, weight: .semibold).foregroundStyle(color)
        }.accessibilityElement(children: .combine)
    }
}
struct SelectedInstructorRow: View {
    let instructor: Instructor
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "person.2").font(.system(size: 20)).foregroundStyle(StudyDesign.blue)
                    .frame(width: 42, height: 42).background(StudyDesign.color(0xE1EDF9, 0x203655), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 5) {
                    Text(instructor.name).selectedText(18, weight: .bold, tracking: -0.3).foregroundStyle(StudyDesign.ink)
                    Text(instructor.squadron.displayName + " · " + instructor.capabilityBadges.map(\.pluralDisplayName).joined(separator: " · "))
                        .selectedText(11).foregroundStyle(StudyDesign.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right").foregroundStyle(StudyDesign.secondary).accessibilityHidden(true)
            }
            SelectedInstructorScores(chill: instructor.averageChillScore, grading: instructor.averageGradingScore)
            Text(instructor.reviewCountText).selectedText(11).foregroundStyle(StudyDesign.secondary)
        }.padding(.vertical, 23)
            .overlay(alignment: .bottom) { Rectangle().fill(StudyDesign.line).frame(height: 1) }
            .contentShape(Rectangle())
    }
}
struct SelectedInstructorReview: View {
    let review: InstructorReview
    let onReport: () -> Void
    var body: some View {
        SelectedSurface {
            VStack(alignment: .leading, spacing: 17) {
                ViewThatFits(in: .horizontal) {
                    HStack { Text(review.eventName ?? review.eventKind.displayName).pilotText(.code); Spacer(); date }
                    VStack(alignment: .leading, spacing: 6) { Text(review.eventName ?? review.eventKind.displayName).pilotText(.code); date }
                }.foregroundStyle(StudyDesign.blue)
                SelectedInstructorScores(chill: Double(review.chillScore), grading: Double(review.gradingScore), compact: true)
                Text(review.reviewText).selectedText(15, line: 24).foregroundStyle(StudyDesign.reading)
                Button("Report review", action: onReport).selectedText(11).foregroundStyle(StudyDesign.secondary).frame(minHeight: 44)
            }
        }
    }
    private var date: some View { Text(review.submittedAt.formatted(date: .abbreviated, time: .omitted)).selectedText(11).foregroundStyle(StudyDesign.secondary) }
}
