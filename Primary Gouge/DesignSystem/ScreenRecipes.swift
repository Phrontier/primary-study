import SwiftUI
import UIKit

/// One scaling engine, with explicit line-box policy to preserve measured screen differences.
struct DesignMeasuredType: ViewModifier {
    @ScaledMetric private var scaledSize: CGFloat
    let size: CGFloat
    let line: CGFloat
    let weight: Font.Weight
    let tracking: CGFloat
    let minimumLineBox: Bool
    init(size: CGFloat, line: CGFloat, weight: Font.Weight, tracking: CGFloat = 0,
         relativeTo: Font.TextStyle, minimumLineBox: Bool = false) {
        self.size = size; self.line = line; self.weight = weight; self.tracking = tracking
        self.minimumLineBox = minimumLineBox
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: relativeTo)
    }
    func body(content: Content) -> some View {
        let scale = scaledSize / size
        let difference = line * scale - UIFont.systemFont(ofSize: scaledSize).lineHeight
        let leading = minimumLineBox ? max(0, difference) : difference
        content.font(.system(size: scaledSize, weight: weight)).tracking(tracking * scale)
            .lineSpacing(leading).padding(.vertical, leading / 2)
            .frame(minHeight: minimumLineBox ? line * scale : nil, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Semantic entry point for future screens; the historical name preserves approved measurements.
typealias DesignTextRole = PilotTextRole
extension View {
    func designText(_ role: DesignTextRole) -> some View { pilotText(role) }
}

/// An open page introduction. Use an identity pill only for a real identifier.
struct DesignPageIntro: View {
    let title: String
    var subtitle: String? = nil
    var identifier: String? = nil
    var body: some View {
        StudyHeading(eyebrow: identifier, title: title, subtitle: subtitle, pill: identifier != nil)
    }
}

/// A reading section, not a card. Its rule denotes hierarchy, not interactivity.
struct DesignReadingSection<Content: View>: View {
    let title: String
    var accent: Color = StudyDesign.teal
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).designText(.readingHeading).accessibilityAddTraits(.isHeader)
                .padding(.leading, 12)
                .overlay(alignment: .leading) { accent.frame(width: 3) }
            content
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Shared empty/error presentation. Actions remain owned by the caller, including retry policy.
struct DesignStateView: View {
    let icon: String
    let title: String
    let message: String
    var isError = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.system(size: 23)).foregroundStyle(isError ? AppTheme.danger : StudyDesign.blue).accessibilityHidden(true)
            Text(title).designText(.section).accessibilityAddTraits(.isHeader)
            Text(message).designText(.body).foregroundStyle(StudyDesign.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 18)
            .accessibilityElement(children: .combine)
    }
}

/// A labeled form section stays open; fields keep their native editing/validation semantics.
struct DesignFormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).designText(.section).accessibilityAddTraits(.isHeader)
            content
        }
    }
}

#if DEBUG
/// Internal visual reference only. No network calls, account writes, entitlement changes, or shipping route.
struct DesignPatternGallery: View {
    @State private var sampleName = ""
    @State private var isExpanded = true
    var body: some View {
        NavigationStack {
            AppScrollScreen {
                DesignPageIntro(title: "Design patterns", subtitle: "Debug reference · sample content")
                DesignReadingSection(title: "Open destinations", accent: StudyDesign.blue) {
                    ToolCard(title: "Cockpit Familiarization", subtitle: "FAM2101 · Discussion items and preparation", icon: "airplane", accent: StudyDesign.blue)
                    ToolCard(title: "A deliberately long destination title that wraps without losing its identifier", subtitle: "FAM2102 · Long-content example", icon: "book", accent: StudyDesign.teal)
                }
                DesignReadingSection(title: "Reading and disclosure") {
                    DisclosureGroup(isExpanded: $isExpanded) {
                        Text("Keep source content complete. Reading belongs to the page; a card is reserved for a bounded interaction or independent submission.").designText(.body).foregroundStyle(StudyDesign.secondary)
                    } label: { Text("Discussion heading").designText(.tool) }
                }
                DesignFormSection(title: "Account or submission") {
                    TextField("Sample name", text: $sampleName).designText(.body).padding(.vertical, 12)
                        .overlay(alignment: .bottom) { StudyDesign.line.frame(height: 1) }
                    StudyActionButton(title: "Primary action", icon: "arrow.right", tint: StudyDesign.action)
                        .accessibilityLabel("Primary action appearance example")
                }
                SelectedSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Independent review or question").designText(.section)
                        Text("Use one surface for one interaction. Avoid enclosing its metadata in more cards.").designText(.body)
                    }
                }
                DesignStateView(icon: "tray", title: "No reviews yet", message: "Missing data stays missing. Do not invent scores or history.")
                DesignStateView(icon: "wifi.exclamationmark", title: "Couldn’t load material", message: "Check your connection and try again. Existing retry behavior belongs to the screen.", isError: true)
            }.navigationTitle("Pattern reference").navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
