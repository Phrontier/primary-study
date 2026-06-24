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
        static let card: CGFloat = 18
        static let largeCard: CGFloat = 22
        static let control: CGFloat = 14
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let screenHorizontal: CGFloat = 20
        static let screenTop: CGFloat = 16
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
                accent: adaptiveColor(light: 0x2563EB, dark: 0x6EA4FF),
                accentSoft: adaptiveColor(light: 0x5E8BFF, dark: 0x9FC1FF),
                accentMuted: adaptiveColor(light: 0xE7F0FF, dark: 0x17243A),
                success: adaptiveColor(light: 0x168A51, dark: 0x4ED18A),
                warning: adaptiveColor(light: 0xB76B00, dark: 0xFFC15A),
                danger: adaptiveColor(light: 0xD8344E, dark: 0xFF7A8E),
                textPrimary: adaptiveColor(light: 0x172033, dark: 0xF4F7FB),
                textSecondary: adaptiveColor(light: 0x5B6472, dark: 0xB4BDCB),
                textMuted: adaptiveColor(light: 0x8B95A5, dark: 0x848EA0),
                pageTop: adaptiveColor(light: 0xF8FAFD, dark: 0x111419),
                pageBottom: adaptiveColor(light: 0xEEF3F8, dark: 0x171B22),
                pageGlow: adaptiveColor(light: 0xD8E7FF, dark: 0x1B2A42),
                surface: adaptiveColor(light: 0xFFFFFF, dark: 0x1B2028),
                elevatedSurface: adaptiveColor(light: 0xFDFEFF, dark: 0x222832),
                raisedSurface: adaptiveColor(light: 0xFFFFFF, dark: 0x29313D),
                sunkenSurface: adaptiveColor(light: 0xE8EEF6, dark: 0x12161D),
                groupedBackground: adaptiveColor(light: 0xF1F5FA, dark: 0x202732),
                secondaryGroupedBackground: adaptiveColor(light: 0xE6ECF4, dark: 0x2A3340),
                separator: adaptiveColor(light: 0xD8E0EA, dark: 0x3A4655),
                cardStroke: adaptiveColor(light: 0xDFE6EF, dark: 0x354150),
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
        liftedColor(color, amount: 0.18)
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

    @ViewBuilder
    static var screenBackground: some View {
        ZStack {
            LinearGradient(
                colors: [palette.pageTop, palette.pageBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [palette.pageGlow.opacity(0.72), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 340
            )
            .offset(y: -170)
        }
    }

    @ViewBuilder
    static func cardBackground(style: SurfaceStyle = .standard, accent: Color = AppTheme.accent) -> some View {
        let radius = style == .hero ? Radius.largeCard : Radius.card
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        shape
            .fill(surfaceFill(style: style, accent: accent))
            .overlay {
                shape.stroke(surfaceStroke(style: style, accent: accent), lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                if style == .rootSummary {
                    shape
                        .fill(
                            RadialGradient(
                                colors: [
                                    liftedColor(accent, amount: 0.10).opacity(0.18),
                                    accent.opacity(0.08),
                                    .clear
                                ],
                                center: .topLeading,
                                startRadius: 8,
                                endRadius: 220
                            )
                        )
                        .blendMode(.screen)
                }
            }
            .overlay(alignment: .top) {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(style == .hero ? 0.18 : 0.10), Color.white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .mask(
                        Rectangle()
                            .fill(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
                    )
            }
            .shadow(color: Color.black.opacity(shadowOpacity(style: style)), radius: shadowRadius(style: style), x: 0, y: shadowYOffset(style: style))
    }

    static func cardBackground(highlighted: Bool = false) -> some View {
        cardBackground(style: highlighted ? .primary : .standard)
    }

    static func subtleFill(_ color: Color) -> some ShapeStyle {
        color.opacity(0.14)
    }

    private static func surfaceFill(style: SurfaceStyle, accent: Color) -> LinearGradient {
        switch style {
        case .hero:
            return LinearGradient(
                colors: [
                    elevatedSurface.opacity(0.98),
                    accent.opacity(0.08),
                    surface.opacity(0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .primary:
            return LinearGradient(
                colors: [
                    raisedSurface.opacity(0.96),
                    accent.opacity(0.08),
                    surface.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rootSummary:
            return LinearGradient(
                colors: [
                    elevatedSurface.opacity(0.98),
                    accent.opacity(0.07),
                    surface.opacity(0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .metric:
            return LinearGradient(
                colors: [
                    groupedBackground.opacity(0.98),
                    accent.opacity(0.06),
                    surface.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .grouped:
            return LinearGradient(
                colors: [groupedBackground.opacity(0.98), surface.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .standard:
            return LinearGradient(
                colors: [surface.opacity(0.99), elevatedSurface.opacity(0.97)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private static func surfaceStroke(style: SurfaceStyle, accent: Color) -> LinearGradient {
        switch style {
        case .hero:
            return LinearGradient(
                colors: [strongStroke.opacity(0.92), accent.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .primary:
            return LinearGradient(
                colors: [cardStroke.opacity(0.95), accent.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rootSummary:
            return LinearGradient(
                colors: [strongStroke.opacity(0.88), accent.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .metric:
            return LinearGradient(
                colors: [cardStroke.opacity(0.94), accent.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .grouped, .standard:
            return LinearGradient(
                colors: [cardStroke.opacity(0.96), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private static func shadowOpacity(style: SurfaceStyle) -> Double {
        switch style {
        case .hero:
            return 0.12
        case .primary:
            return 0.10
        case .rootSummary:
            return 0.09
        case .metric:
            return 0.08
        case .grouped:
            return 0.06
        case .standard:
            return 0.08
        }
    }

    private static func shadowRadius(style: SurfaceStyle) -> CGFloat {
        switch style {
        case .hero:
            return 28
        case .primary:
            return 22
        case .rootSummary:
            return 18
        case .metric:
            return 18
        case .grouped:
            return 14
        case .standard:
            return 16
        }
    }

    private static func shadowYOffset(style: SurfaceStyle) -> CGFloat {
        switch style {
        case .hero:
            return 16
        case .primary:
            return 12
        case .rootSummary:
            return 11
        case .metric:
            return 10
        case .grouped:
            return 8
        case .standard:
            return 10
        }
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
