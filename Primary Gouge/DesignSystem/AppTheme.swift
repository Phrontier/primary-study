import SwiftUI
import UIKit

enum AppTheme {
    enum ThemeVariant {
        case nativeClarity
    }

    struct ThemePalette {
        let accent: Color
        let accentSoft: Color
        let accentMuted: Color
        let success: Color
        let warning: Color
        let danger: Color

        let textPrimary: Color
        let textSecondary: Color
        let textMuted: Color

        let pageTop: Color
        let pageBottom: Color
        let pageGlow: Color

        let surface: Color
        let elevatedSurface: Color
        let raisedSurface: Color
        let sunkenSurface: Color
        let groupedBackground: Color
        let secondaryGroupedBackground: Color
        let separator: Color
        let cardStroke: Color
        let strongStroke: Color

        let chromeBackground: UIColor
        let chromeLine: UIColor
    }

    enum Radius {
        static let card: CGFloat = 24
        static let largeCard: CGFloat = 22
        static let control: CGFloat = 13
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let screenHorizontal: CGFloat = 22
        static let screenTop: CGFloat = 18
        static let rootTabIntroTop: CGFloat = 8
        static let section: CGFloat = 28
        static let group: CGFloat = 16
        static let compact: CGFloat = 10
    }

    enum SurfaceStyle {
        case hero
        case primary
        case rootSummary
        case standard
        case grouped
        case metric
    }

    enum StatusColorRole {
        case critical
        case danger
        case warning
        case neutral
        case success
        case approved
        case rejected
        case pending
    }

    enum DomainColorRole {
        case primary
        case discussionItems
        case flashcards
        case quizzes
        case instructors
        case videos
        case resources
        case library
        case documents
        case groundSchool
        case sims
        case flights
        case account
        case support
    }

    static let activeVariant: ThemeVariant = .nativeClarity

    static var preferredColorScheme: ColorScheme? {
        switch activeVariant {
        case .nativeClarity:
            return nil
        }
    }

    static var palette: ThemePalette {
        switch activeVariant {
        case .nativeClarity:
            return ThemePalette(
                accent: StudyDesign.blue,
                accentSoft: adaptiveColor(light: 0x5E8BFF, dark: 0x9FC1FF),
                accentMuted: adaptiveColor(light: 0xE7F0FF, dark: 0x17243A),
                success: adaptiveColor(light: 0x168A51, dark: 0x4ED18A),
                warning: adaptiveColor(light: 0xB76B00, dark: 0xFFC15A),
                danger: adaptiveColor(light: 0xD8344E, dark: 0xFF7A8E),
                textPrimary: StudyDesign.ink,
                textSecondary: StudyDesign.secondary,
                textMuted: StudyDesign.secondary,
                pageTop: StudyDesign.page,
                pageBottom: StudyDesign.page,
                pageGlow: StudyDesign.page,
                surface: StudyDesign.surface,
                elevatedSurface: adaptiveColor(light: 0xFDFEFF, dark: 0x222832),
                raisedSurface: adaptiveColor(light: 0xFFFFFF, dark: 0x29313D),
                sunkenSurface: adaptiveColor(light: 0xE8EEF6, dark: 0x12161D),
                groupedBackground: adaptiveColor(light: 0xF1F5FA, dark: 0x202732),
                secondaryGroupedBackground: adaptiveColor(light: 0xE6ECF4, dark: 0x2A3340),
                separator: StudyDesign.line,
                cardStroke: StudyDesign.cardLine,
                strongStroke: adaptiveColor(light: 0xC9D6E8, dark: 0x4A5A6D),
                chromeBackground: adaptiveUIColor(light: 0xFBFCFE, dark: 0x151A22, alpha: 0.82),
                chromeLine: adaptiveUIColor(light: 0xCBD5E1, dark: 0x303B4A, alpha: 0.72)
            )
        }
    }

    static var accent: Color { palette.accent }
    static var accentSoft: Color { palette.accentSoft }
    static var accentMuted: Color { palette.accentMuted }
    static var success: Color { palette.success }
    static var warning: Color { palette.warning }
    static var danger: Color { palette.danger }

    static var textPrimary: Color { palette.textPrimary }
    static var textSecondary: Color { palette.textSecondary }
    static var textMuted: Color { palette.textMuted }

    static var surface: Color { palette.surface }
    static var elevatedSurface: Color { palette.elevatedSurface }
    static var raisedSurface: Color { palette.raisedSurface }
    static var sunkenSurface: Color { palette.sunkenSurface }
    static var groupedBackground: Color { palette.groupedBackground }
    static var secondaryGroupedBackground: Color { palette.secondaryGroupedBackground }
    static var separator: Color { palette.separator }
    static var cardStroke: Color { palette.cardStroke }
    static var strongStroke: Color { palette.strongStroke }

    /// Preserve readable text on semantic action fills in both appearances.
    static func foreground(on fill: Color, scheme: ColorScheme) -> Color {
        let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
        let resolved = UIColor(fill).resolvedColor(with: traits)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return .white }
        func linear(_ value: CGFloat) -> CGFloat { value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        return luminance > 0.179 ? .black : .white
    }

    static func statusColor(_ role: StatusColorRole) -> Color {
        switch role {
        case .critical:
            return color(0xFF4D5E)
        case .danger, .rejected:
            return danger
        case .warning, .pending:
            return warning
        case .neutral:
            return accent
        case .success, .approved:
            return success
        }
    }

    static func domainColor(_ role: DomainColorRole) -> Color {
        switch role {
        case .primary:
            return accent
        case .discussionItems:
            return adaptiveColor(light: 0x0D9488, dark: 0x5FD3B8)
        case .flashcards:
            return adaptiveColor(light: 0x6D5BD0, dark: 0xA494FF)
        case .quizzes:
            return adaptiveColor(light: 0x0B83C9, dark: 0x5AC8FF)
        case .instructors:
            return adaptiveColor(light: 0x7157D9, dark: 0xA997FF)
        case .videos:
            return adaptiveColor(light: 0xD54E70, dark: 0xFF7D9A)
        case .library:
            return adaptiveColor(light: 0x9A6A2E, dark: 0xD9A866)
        case .resources:
            return adaptiveColor(light: 0x2563EB, dark: 0x7EA8FF)
        case .documents:
            return adaptiveColor(light: 0x9A6A2E, dark: 0xD9A866)
        case .groundSchool:
            return adaptiveColor(light: 0x248A45, dark: 0x5FD985)
        case .sims:
            return adaptiveColor(light: 0xB87400, dark: 0xF4BE53)
        case .flights:
            return adaptiveColor(light: 0x1F75D6, dark: 0x72B8FF)
        case .account:
            return adaptiveColor(light: 0x4E69D9, dark: 0x91A8FF)
        case .support:
            return adaptiveColor(light: 0x64748B, dark: 0xA4AFC4)
        }
    }

    static func semanticTint(_ color: Color, opacity: Double = 0.16) -> Color {
        liftedColor(color, amount: 0.06).opacity(opacity)
    }

    static func subtleBackground(_ color: Color) -> Color {
        liftedColor(color, amount: 0.06).opacity(0.14)
    }

    static func subtleBackground(_ role: StatusColorRole) -> Color {
        subtleBackground(statusColor(role))
    }

    static func subtleBackground(_ role: DomainColorRole) -> Color {
        subtleBackground(domainColor(role))
    }

    static func badgeFill(_ color: Color) -> Color {
        liftedColor(color, amount: 0.10).opacity(0.20)
    }

    static func badgeFill(_ role: StatusColorRole) -> Color {
        badgeFill(statusColor(role))
    }

    static func badgeFill(_ role: DomainColorRole) -> Color {
        badgeFill(domainColor(role))
    }

    static func badgeStroke(_ color: Color) -> Color {
        liftedColor(color, amount: 0.14).opacity(0.44)
    }

    static func badgeStroke(_ role: StatusColorRole) -> Color {
        badgeStroke(statusColor(role))
    }

    static func badgeStroke(_ role: DomainColorRole) -> Color {
        badgeStroke(domainColor(role))
    }

    static func iconTint(_ color: Color) -> Color {
        liftedColor(color, amount: 0.10)
    }

    static func iconTint(_ role: StatusColorRole) -> Color {
        iconTint(statusColor(role))
    }

    static func iconTint(_ role: DomainColorRole) -> Color {
        iconTint(domainColor(role))
    }

    static func prominentText(_ color: Color) -> Color {
        color
    }

    static func prominentText(_ role: StatusColorRole) -> Color {
        prominentText(statusColor(role))
    }

    static func prominentText(_ role: DomainColorRole) -> Color {
        prominentText(domainColor(role))
    }

    static func accessoryTint(_ color: Color) -> Color {
        liftedColor(color, amount: 0.12).opacity(0.82)
    }

    static func accessoryTint(_ role: DomainColorRole) -> Color {
        accessoryTint(domainColor(role))
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentSoft.opacity(0.96), accent.opacity(0.94)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.18),
                accentSoft.opacity(0.10),
                Color.white.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func configureSystemChrome() {
        let selectedColor = UIColor(accent)
        let normalColor = adaptiveUIColor(light: 0x7C8694, dark: 0xA0A8B5)

        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = normalColor
        UITabBar.appearance().isTranslucent = true

        UINavigationBar.appearance().tintColor = selectedColor
        UINavigationBar.appearance().prefersLargeTitles = true
    }

    /// Compatibility entry point. New screens use StudyDesign and screen recipes.
    @ViewBuilder
    static var screenBackground: some View {
        StudyDesign.page
    }

    @ViewBuilder
    static func cardBackground(style: SurfaceStyle = .standard, accent: Color = AppTheme.accent) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(StudyDesign.surface)
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(StudyDesign.cardLine, lineWidth: 1))
    }

    static func cardBackground(highlighted: Bool = false) -> some View {
        cardBackground(style: highlighted ? .primary : .standard)
    }

    static func subtleFill(_ color: Color) -> some ShapeStyle {
        color.opacity(0.14)
    }

    static func color(_ rgb: UInt32) -> Color {
        Color(uiColor: UIColor(rgb: rgb))
    }

    private static func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: adaptiveUIColor(light: light, dark: dark))
    }

    private static func adaptiveUIColor(light: UInt32, dark: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(rgb: value).withAlphaComponent(alpha)
        }
    }

    private static func liftedColor(_ color: Color, amount: CGFloat) -> Color {
        Color(uiColor: UIColor(color).mixed(with: .white, amount: amount))
    }
}

struct GlassCard<Content: View>: View {
    let highlighted: Bool
    @ViewBuilder var content: Content

    init(highlighted: Bool = false, @ViewBuilder content: () -> Content) {
        self.highlighted = highlighted
        self.content = content()
    }

    var body: some View {
        content
            .padding(highlighted ? 24 : 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground(style: highlighted ? .primary : .standard))
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        let red = CGFloat((rgb >> 16) & 0xFF) / 255
        let green = CGFloat((rgb >> 8) & 0xFF) / 255
        let blue = CGFloat(rgb & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    func mixed(with color: UIColor, amount: CGFloat) -> UIColor {
        var baseRed: CGFloat = 0
        var baseGreen: CGFloat = 0
        var baseBlue: CGFloat = 0
        var baseAlpha: CGFloat = 0
        var targetRed: CGFloat = 0
        var targetGreen: CGFloat = 0
        var targetBlue: CGFloat = 0
        var targetAlpha: CGFloat = 0

        guard
            getRed(&baseRed, green: &baseGreen, blue: &baseBlue, alpha: &baseAlpha),
            color.getRed(&targetRed, green: &targetGreen, blue: &targetBlue, alpha: &targetAlpha)
        else {
            return self
        }

        let ratio = max(0, min(amount, 1))

        return UIColor(
            red: baseRed + (targetRed - baseRed) * ratio,
            green: baseGreen + (targetGreen - baseGreen) * ratio,
            blue: baseBlue + (targetBlue - baseBlue) * ratio,
            alpha: baseAlpha + (targetAlpha - baseAlpha) * ratio
        )
    }
}
