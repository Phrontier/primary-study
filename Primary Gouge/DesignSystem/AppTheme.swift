import SwiftUI
import UIKit

enum AppTheme {
    enum Radius {
        static let card: CGFloat = 22
        static let largeCard: CGFloat = 26
        static let control: CGFloat = 16
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let screenHorizontal: CGFloat = 20
        static let screenTop: CGFloat = 18
        static let section: CGFloat = 28
        static let group: CGFloat = 16
        static let compact: CGFloat = 10
    }

    enum SurfaceStyle {
        case hero
        case primary
        case standard
        case grouped
        case metric
    }

    static let accent = Color(red: 0.13, green: 0.43, blue: 0.88)
    static let accentSoft = Color(red: 0.43, green: 0.64, blue: 0.95)
    static let accentMuted = Color(red: 0.86, green: 0.91, blue: 0.97)
    static let success = Color(red: 0.14, green: 0.63, blue: 0.42)
    static let warning = Color(red: 0.87, green: 0.56, blue: 0.09)
    static let danger = Color(red: 0.80, green: 0.28, blue: 0.23)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textMuted = Color(uiColor: .tertiaryLabel)

    static let surface = dynamicColor(light: 0xF4F7FB, dark: 0x10151D)
    static let elevatedSurface = dynamicColor(light: 0xFFFFFF, dark: 0x18202B)
    static let raisedSurface = dynamicColor(light: 0xEEF3F8, dark: 0x202A36)
    static let sunkenSurface = dynamicColor(light: 0xE8EEF5, dark: 0x0D1219)
    static let groupedBackground = dynamicColor(light: 0xEFF3F8, dark: 0x111823)
    static let secondaryGroupedBackground = dynamicColor(light: 0xE8EEF5, dark: 0x18212C)
    static let separator = dynamicColor(light: 0xD8E0E9, dark: 0x2A3542)
    static let cardStroke = dynamicColor(light: 0xD9E1EA, dark: 0x313C49)
    static let strongStroke = dynamicColor(light: 0xCDD9E7, dark: 0x415063)

    static let accentGradient = LinearGradient(
        colors: [accent.opacity(0.94), accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            accent.opacity(0.22),
            accentSoft.opacity(0.14),
            Color.white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func configureSystemChrome() {
        let backgroundColor = UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? 0x131A23 : 0xF7FAFD).withAlphaComponent(0.86)
        }
        let lineColor = UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? 0x334050 : 0xD7E0EA).withAlphaComponent(0.65)
        }

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = backgroundColor
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        tabBarAppearance.shadowColor = lineColor

        let selectedColor = UIColor(accent)
        let normalColor = UIColor.secondaryLabel

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

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = backgroundColor.withAlphaComponent(0.70)
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        navAppearance.shadowColor = lineColor.withAlphaComponent(0.18)

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    @ViewBuilder
    static var screenBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    dynamicColor(light: 0xF5F8FC, dark: 0x0C1118),
                    dynamicColor(light: 0xF2F6FB, dark: 0x0F151E),
                    dynamicColor(light: 0xF7F9FC, dark: 0x111823)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    accent.opacity(0.08),
                    accent.opacity(0.03),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxHeight: 240)
            .offset(y: -120)
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
            .overlay(alignment: .top) {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(style == .hero ? 0.26 : 0.16), Color.white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                            )
                    )
            }
            .shadow(color: shadowColor(style: style).opacity(shadowOpacity(style: style)), radius: shadowRadius(style: style), x: 0, y: shadowYOffset(style: style))
            .shadow(color: Color.black.opacity(style == .hero ? 0.025 : 0.014), radius: style == .hero ? 18 : 12, x: 0, y: style == .hero ? 10 : 6)
    }

    static func cardBackground(highlighted: Bool = false) -> some View {
        cardBackground(style: highlighted ? .primary : .standard)
    }

    static func subtleFill(_ color: Color) -> some ShapeStyle {
        color.opacity(0.12)
    }

    private static func surfaceFill(style: SurfaceStyle, accent: Color) -> LinearGradient {
        switch style {
        case .hero:
            return LinearGradient(
                colors: [
                    elevatedSurface.opacity(0.98),
                    accentMuted.opacity(0.52),
                    surface.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .primary:
            return LinearGradient(
                colors: [
                    elevatedSurface.opacity(0.995),
                    accent.opacity(0.05),
                    surface.opacity(0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .grouped:
            return LinearGradient(
                colors: [raisedSurface.opacity(0.88), elevatedSurface.opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .metric:
            return LinearGradient(
                colors: [
                    elevatedSurface.opacity(0.99),
                    accent.opacity(0.045),
                    surface.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .standard:
            return LinearGradient(
                colors: [surface.opacity(0.98), elevatedSurface.opacity(0.97)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private static func surfaceStroke(style: SurfaceStyle, accent: Color) -> LinearGradient {
        switch style {
        case .hero:
            return LinearGradient(
                colors: [strongStroke.opacity(0.78), accent.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .primary:
            return LinearGradient(
                colors: [cardStroke.opacity(0.95), accent.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .metric:
            return LinearGradient(
                colors: [cardStroke.opacity(0.95), accent.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .grouped, .standard:
            return LinearGradient(
                colors: [cardStroke.opacity(0.94), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private static func shadowColor(style: SurfaceStyle) -> Color {
        Color.black
    }

    private static func shadowOpacity(style: SurfaceStyle) -> Double {
        switch style {
        case .hero:
            return 0.07
        case .primary:
            return 0.055
        case .metric:
            return 0.045
        case .grouped:
            return 0.032
        case .standard:
            return 0.026
        }
    }

    private static func shadowRadius(style: SurfaceStyle) -> CGFloat {
        switch style {
        case .hero:
            return 24
        case .primary:
            return 18
        case .metric:
            return 14
        case .grouped:
            return 10
        case .standard:
            return 12
        }
    }

    private static func shadowYOffset(style: SurfaceStyle) -> CGFloat {
        switch style {
        case .hero:
            return 12
        case .primary:
            return 8
        case .metric:
            return 6
        case .grouped:
            return 4
        case .standard:
            return 6
        }
    }

    private static func dynamicColor(light: UInt32, dark: UInt32) -> Color {
        Color(
            uiColor: UIColor { traits in
                UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
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
}
