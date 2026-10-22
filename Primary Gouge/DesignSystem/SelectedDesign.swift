import SwiftUI

/// Measured type for the selected account, roster and membership studies.
extension View {
    func selectedText(_ size: CGFloat, line: CGFloat? = nil, weight: Font.Weight = .regular, tracking: CGFloat = 0) -> some View {
        modifier(DesignMeasuredType(size: size, line: line ?? size * 1.4, weight: weight, tracking: tracking, relativeTo: size >= 28 ? .largeTitle : size >= 21 ? .title2 : size <= 12 ? .caption : .body))
    }
}
struct SelectedPrimaryLabel: View {
    let title: String
    var cornerRadius: CGFloat = 24
    var fontSize: CGFloat = 15
    var weight: Font.Weight = .semibold
    var body: some View {
        Text(title).selectedText(fontSize, line: fontSize * 1.4, weight: weight).foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.horizontal, 15).padding(.vertical, 14)
            .frame(minHeight: 49).background(StudyDesign.action, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
struct SelectedSurface<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(StudyDesign.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(StudyDesign.cardLine, lineWidth: 1))
    }
}
/// Decorative product illustration, reproducing the selected onboarding A composition.
struct OnboardingProductArt: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 9) {
                Capsule().fill(StudyDesign.ink).frame(width: 54, height: 9).frame(maxWidth: .infinity)
                Text("PRIMARY GOUGE").font(.system(size: 6)).foregroundStyle(StudyDesign.secondary)
                Text("Good evening.").font(.system(size: 14, weight: .bold))
                HStack { Text("🔥 4 day streak"); Spacer(); Text("12 reviewed") }.font(.system(size: 6))
                VStack(alignment: .leading, spacing: 8) {
                    Text("I2103").font(.system(size: 7)).foregroundStyle(StudyDesign.blue)
                    Text("Approach Maneuver").font(.system(size: 10, weight: .bold))
                    Text("Resume →").font(.system(size: 8)).foregroundStyle(.white).padding(7).frame(maxWidth: .infinity, alignment: .leading).background(StudyDesign.action, in: RoundedRectangle(cornerRadius: 6))
                }.padding(12).background(StudyDesign.blueFill, in: RoundedRectangle(cornerRadius: 12))
                ForEach(["FAM2101", "FAM2102"], id: \.self) { code in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(code).font(.system(size: 6)).foregroundStyle(StudyDesign.blue)
                        Text(code == "FAM2101" ? "Cockpit Familiarization" : "Ground Emergencies").font(.system(size: 8, weight: .bold))
                    }.padding(.vertical, 4)
                    Rectangle().fill(StudyDesign.line).frame(height: 1)
                }
                Text("Question of the day\nReady for your next event?").font(.system(size: 7)).padding(8).background(StudyDesign.surface, in: RoundedRectangle(cornerRadius: 10))
            }.padding(11).frame(width: 180, height: 310).background(StudyDesign.page, in: RoundedRectangle(cornerRadius: 27))
                .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(StudyDesign.color(0xEEF0F4, 0x34465D), lineWidth: 7))
                .rotationEffect(.degrees(-4)).shadow(color: .black.opacity(0.08), radius: 12, y: 10)
            VStack(alignment: .leading, spacing: 6) {
                Text("FAM2101").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(StudyDesign.blue)
                Text("Cockpit Familiarization").font(.system(size: 17, weight: .bold)).tracking(-0.3)
                Text("Discussion items · Flashcards").font(.system(size: 10)).foregroundStyle(StudyDesign.secondary)
            }.padding(.horizontal, 17).padding(.vertical, 15).frame(maxWidth: .infinity, alignment: .leading)
                .background(StudyDesign.surface, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(StudyDesign.cardLine, lineWidth: 1))
                .rotationEffect(.degrees(2)).shadow(color: .black.opacity(0.09), radius: 14, y: 12)
        }.frame(height: 328).foregroundStyle(StudyDesign.ink).accessibilityHidden(true)
    }
}
struct PremiumAviationArt: View {
    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.08)).overlay(Circle().stroke(.white.opacity(0.2))).frame(width: 76, height: 76).offset(x: 22, y: -2)
            Path { p in p.move(to: CGPoint(x: 16, y: 90)); p.addCurve(to: CGPoint(x: 130, y: 48), control1: CGPoint(x: 80, y: 90), control2: CGPoint(x: 95, y: 60)) }
                .stroke(.white.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3,5]))
            Image(systemName: "paperplane.fill").font(.system(size: 56, weight: .light)).rotationEffect(.degrees(-5)).foregroundStyle(.white).offset(x: 18, y: -2)
            Image(systemName: "plus").font(.system(size: 12)).foregroundStyle(Color.yellow.opacity(0.7)).offset(x: -50, y: -32)
        }.frame(width: 180, height: 105).accessibilityHidden(true)
    }
}

/// The integrated blue header also fills the system status-bar safe area.
struct SelectedHeroPageBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                StudyDesign.page
                StudyDesign.action.frame(height: geometry.safeAreaInsets.top + 1)
            }.ignoresSafeArea()
        }
    }
}
