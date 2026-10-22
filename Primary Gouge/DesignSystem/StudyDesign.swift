import SwiftUI
import UIKit

/// Canonical approved app palette. AppTheme is a compatibility facade for older call sites.
enum StudyDesign {
    static func color(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
    static let page = color(0xF5F7FB, 0x111923)
    static let ink = color(0x18263B, 0xE8EEF8)
    static let secondary = color(0x637086, 0xA9B5C7)
    static let blue = color(0x2867DA, 0x8FB8FF)
    static let action = Color(red: 40 / 255, green: 103 / 255, blue: 218 / 255)
    static let surface = color(0xFFFFFF, 0x1D2736)
    static let line = color(0xE0E6EE, 0x34465D)
    static let blueFill = color(0xE0EBFF, 0x203655)
    static let blueEnd = color(0xEDF2FF, 0x243149)
    static let greenFill = color(0xE2F1E9, 0x203C33)
    static let greenInk = color(0x235B43, 0xA6E0BE)
    static let amberFill = color(0xFFF0D4, 0x443522)
    static let amberInk = color(0x8D601B, 0xF1CA79)
}


extension StudyDesign {
    static let teal = color(0x138B83, 0x8BD7BF)
    static let purple = color(0x8064C7, 0xB6A4EF)
    static let answerGreen = color(0x23734F, 0x8BD7AF)
    static let reading = color(0x4E5C70, 0xA9B5C7)
    static let cardLine = color(0xE4E9F1, 0x34465D)
    static func phaseIcon(_ id: String) -> String {
        switch id {
        case "contacts": "paperplane"
        case "instruments": "arrow.right"
        default: "book"
        }
    }
    static func phaseFill(_ id: String) -> Color {
        switch id {
        case "instruments": color(0xEEE8FA, 0x302942)
        case "vnav": color(0xDEF1EC, 0x203C38)
        case "formation": color(0xF7EBD7, 0x443522)
        default: color(0xE1EDF9, 0x203655)
        }
    }
    static func phaseAccent(_ id: String) -> Color {
        switch id {
        case "instruments": color(0x7960B7, 0xB6A4EF)
        case "vnav": teal
        case "formation": amberInk
        default: blue
        }
    }
}

struct StudyScreen<Content: View>: View {
    var bottomPadding: CGFloat = 32
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, bottomPadding)
        }
        .background(StudyDesign.page.ignoresSafeArea())
        .foregroundStyle(StudyDesign.ink)
        .tint(StudyDesign.blue)
    }
}

struct StudyHeading: View {
    var eyebrow: String? = nil
    let title: String
    var subtitle: String? = nil
    var pill = false
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let eyebrow, !eyebrow.isEmpty {
                Text(eyebrow).pilotText(compact ? .sessionPill : (pill ? .pill : .code))
                    .foregroundStyle(StudyDesign.blue)
                    .padding(.horizontal, pill ? 10 : 0).padding(.vertical, pill ? 7 : 0)
                    .background(pill ? StudyDesign.color(0xE1EDF9, 0x243853) : .clear,
                                in: RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, compact ? 8 : 10)
            }
            Text(title).pilotText(compact ? .sessionTitle : .title).accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("pilot-title-\(title)")
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle).pilotText(.subtitle).foregroundStyle(StudyDesign.secondary).padding(.top, 10)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StudySurface<Content: View>: View {
    var fill: Color = StudyDesign.surface
    var padding: CGFloat = 20
    var featured = false
    @ViewBuilder let content: Content

    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
             .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(featured ? AnyShapeStyle(LinearGradient(colors: [StudyDesign.blueFill, StudyDesign.blueEnd], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(fill)))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(StudyDesign.line, lineWidth: 1))
    }
}

struct StudyDestinationRow: View {
    enum Layout { case root, tool, library }
    let title: String
    var subtitle: String? = nil
    var iconName: String = "arrow.right"
    var accent: Color = StudyDesign.blue
    var highlight: Color? = nil
    var iconFill: Color? = nil
    var layout: Layout = .tool
    var separator = true
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder private var rowContent: some View {
        if layout == .root && dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                HStack { icon; Spacer(); arrow }
                copy
            }
        } else {
            HStack(spacing: 14) { icon; copy; arrow }
        }
    }
    private var icon: some View {
        Image(systemName: iconName).font(.system(size: layout == .root ? 22 : 19, weight: .regular))
            .foregroundStyle(accent).frame(width: layout == .root ? 46 : 42, height: layout == .root ? 46 : 42)
            .background(iconFill ?? accent.opacity(0.12), in: RoundedRectangle(cornerRadius: layout == .root ? 14 : 13))
            .accessibilityHidden(true)
    }
    private var copy: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).pilotText(layout == .root ? .destination : (layout == .library ? .library : .tool))
                .foregroundStyle(StudyDesign.ink).padding(.vertical, 4)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle).pilotText(.metadata).foregroundStyle(StudyDesign.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var arrow: some View {
        Image(systemName: "arrow.right").font(.system(size: 16, weight: .regular))
            .foregroundStyle(highlight == nil ? StudyDesign.secondary : accent).accessibilityHidden(true)
    }
    var body: some View {
        rowContent
        .padding(.vertical, layout == .root ? 23 : (layout == .library ? 19 : 14))
        .padding(.bottom, highlight == nil && separator ? 1 : 0)
        .padding(.horizontal, highlight == nil ? 0 : 14)
        .background(highlight ?? .clear, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            if highlight != nil { RoundedRectangle(cornerRadius: 20).strokeBorder(StudyDesign.color(0xECDDC3, 0x59472F), lineWidth: 1) }
        }
        .overlay(alignment: .bottom) {
            if highlight == nil && separator { Rectangle().fill(StudyDesign.line).frame(height: 1) }
        }
        .contentShape(Rectangle())
    }
}

struct StudyEventRow: View {
    let event: Event
    var isPremiumLocked = false
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack(alignment: .leading, spacing: 0) {
                Text(event.code).pilotText(.code).foregroundStyle(StudyDesign.blue)
                Text(event.displayTitle).pilotText(.destination).foregroundStyle(StudyDesign.ink).padding(.vertical, 7)
                Text(event.summary).pilotText(.subtitle).foregroundStyle(StudyDesign.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: isPremiumLocked ? "lock" : "arrow.right")
                .font(.system(size: 16, weight: .regular)).foregroundStyle(StudyDesign.secondary)
                .padding(.top, 4).accessibilityHidden(true)
        }
        .padding(.vertical, 22)
        .overlay(alignment: .top) { Rectangle().fill(StudyDesign.line).frame(height: 1) }
        .contentShape(Rectangle())
    }
}
