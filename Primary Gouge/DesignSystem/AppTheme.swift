import SwiftUI
import UIKit

enum AppTheme {
    enum ThemeVariant {
        case baselineDark
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
        static let card: CGFloat = 20
        static let largeCard: CGFloat = 24
        static let control: CGFloat = 16
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let screenHorizontal: CGFloat = 20
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
        case scripts
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

    static let activeVariant: ThemeVariant = .baselineDark

    static var preferredColorScheme: ColorScheme? {
        switch activeVariant {
        case .baselineDark:
            return .dark
        }
    }

    static var palette: ThemePalette {
        switch activeVariant {
        case .baselineDark:
            return ThemePalette(
                accent: color(0x4A88FF),
                accentSoft: color(0x7DA8FF),
                accentMuted: color(0x1A2433),
                success: color(0x36C276),
                warning: color(0xFFB454),
                danger: color(0xFF6B6B),
                textPrimary: color(0xF4F7FB),
                textSecondary: color(0xA8B3C7),
                textMuted: color(0x7E8A9E),
                pageTop: color(0x07101B),
                pageBottom: color(0x0B1420),
                pageGlow: color(0x12243E),
                surface: color(0x101A27),
                elevatedSurface: color(0x142131),
                raisedSurface: color(0x182638),
                sunkenSurface: color(0x0C131D),
                groupedBackground: color(0x122030),
                secondaryGroupedBackground: color(0x1A293B),
                separator: color(0x273548),
                cardStroke: color(0x2A3A4D),
                strongStroke: color(0x39516C),
                chromeBackground: UIColor(rgb: 0x0A131E).withAlphaComponent(0.90),
                chromeLine: UIColor(rgb: 0x263447).withAlphaComponent(0.72)
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
            return color(0x5FD3B8)
        case .flashcards:
            return color(0x8B74FF)
        case .quizzes:
            return color(0x45C7FF)
        case .instructors:
            return color(0x9A86FF)
        case .scripts:
            return color(0xF3A84D)
        case .videos:
            return color(0xFF6F91)
        case .library:
            return color(0xBE8B52)
        case .resources:
            return color(0x6E9CFF)
        case .documents:
            return color(0xBE8B52)
        case .groundSchool:
            return color(0x4CC56F)
        case .sims:
            return color(0xE3A93B)
        case .flights:
            return color(0x58AFFF)
        case .account:
            return color(0x7E9BFF)
        case .support:
            return color(0x8C96B4)
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
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = palette.chromeBackground
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        tabBarAppearance.shadowColor = palette.chromeLine

        let selectedColor = UIColor(accent)
        let normalColor = UIColor(rgb: 0x7F8CA2)

        let itemAppearances = [
            tabBarAppearance.stackedLayoutAppearance,
            tabBarAppearance.inlineLayoutAppearance,
            tabBarAppearance.compactInlineLayoutAppearance
        ]
        for itemAppearance in itemAppearances {
            itemAppearance.normal.iconColor = normalColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        }

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

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
                    elevatedSurface.opacity(0.96),
                    accent.opacity(0.12),
                    surface.opacity(0.96)
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
                colors: [surface.opacity(0.98), elevatedSurface.opacity(0.96)],
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
            return 0.28
        case .primary:
            return 0.22
        case .rootSummary:
            return 0.20
        case .metric:
            return 0.18
        case .grouped:
            return 0.16
        case .standard:
            return 0.18
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
