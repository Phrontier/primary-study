import SwiftUI

struct ScreenScaffold<Content: View>: View {
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let showsIndicators: Bool
    @ViewBuilder var content: Content

    init(
        horizontalPadding: CGFloat = AppTheme.Spacing.screenHorizontal,
        topPadding: CGFloat = AppTheme.Spacing.screenTop,
        bottomPadding: CGFloat = 40,
        showsIndicators: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: showsIndicators) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    content
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
        }
    }
}

struct AppScrollScreen<Content: View>: View {
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    @ViewBuilder var content: Content

    init(
        horizontalPadding: CGFloat = AppTheme.Spacing.screenHorizontal,
        topPadding: CGFloat = AppTheme.Spacing.screenTop,
        bottomPadding: CGFloat = 40,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.content = content()
    }

    var body: some View {
        ScreenScaffold(
            horizontalPadding: horizontalPadding,
            topPadding: topPadding,
            bottomPadding: bottomPadding,
            content: { content }
        )
    }
}

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 4 : 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .tracking(0.6)

            Text(title)
                .font((subtitle == nil ? Font.title2 : .title3).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 520, alignment: .leading)
            }
        }
    }
}

struct SectionContainer<Content: View>: View {
    let style: AppTheme.SurfaceStyle
    let accent: Color
    let contentPadding: CGFloat
    @ViewBuilder let content: Content

    init(
        highlighted: Bool = false,
        style: AppTheme.SurfaceStyle? = nil,
        accent: Color = AppTheme.accent,
        contentPadding: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style ?? (highlighted ? .primary : .standard)
        self.accent = accent
        self.contentPadding = contentPadding ?? (highlighted ? 24 : 20)
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.cardBackground(style: style, accent: accent)
            )
    }
}

struct HeroCard<Content: View>: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    let accent: Color
    @ViewBuilder let content: Content

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        accent: Color = AppTheme.accent,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        SectionContainer(style: .hero, accent: accent, contentPadding: 24) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 14 : 18) {
                VStack(alignment: .leading, spacing: subtitle == nil ? 4 : 8) {
                    if let eyebrow, !eyebrow.isEmpty {
                        Text(eyebrow.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                            .tracking(0.6)
                    }

                    Text(title)
                        .font(.system(size: subtitle == nil ? 34 : 30, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 540, alignment: .leading)
                    }
                }

                content
            }
        }
    }
}

struct TabHeaderIdentity {
    let navigationTitle: String
    let eyebrow: String
    let title: String
    let subtitle: String?
    let iconName: String
    let accent: Color
}

struct ScrollActivatedNavigationChrome: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

extension View {
    func scrollActivatedNavigationChrome(title: String) -> some View {
        modifier(ScrollActivatedNavigationChrome(title: title))
    }
}

struct TabHeaderMetric: Identifiable, Hashable {
    let id: String
    let label: String
    let value: String
    let color: Color
    let iconName: String?

    init(label: String, value: String, color: Color, iconName: String? = nil) {
        self.id = "\(label)-\(value)-\(iconName ?? "")"
        self.label = label
        self.value = value
        self.color = color
        self.iconName = iconName
    }
}

enum TabHeaderMetricLayout {
    case adaptive
    case compactRow
}

struct HeroInlineMetric: Identifiable, Hashable {
    let id: String
    let label: String
    let value: String
    let color: Color

    init(label: String, value: String, color: Color) {
        self.id = "\(label)-\(value)"
        self.label = label
        self.value = value
        self.color = color
    }
}

struct HeaderCapsuleButton: View {
    let title: String
    let iconName: String
    let tint: Color

    init(title: String, iconName: String, tint: Color = AppTheme.accent) {
        self.title = title
        self.iconName = iconName
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))

            Text(title)
                .font(.footnote.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(AppTheme.badgeFill(tint))
                .overlay(
                    Capsule()
                        .stroke(AppTheme.badgeStroke(tint), lineWidth: 1)
                )
        )
    }
}

struct TabHeaderCard<Content: View>: View {
    let identity: TabHeaderIdentity
    let metrics: [TabHeaderMetric]
    let metricLayout: TabHeaderMetricLayout
    @ViewBuilder let content: Content

    init(
        identity: TabHeaderIdentity,
        metrics: [TabHeaderMetric] = [],
        metricLayout: TabHeaderMetricLayout = .adaptive,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.identity = identity
        self.metrics = metrics
        self.metricLayout = metricLayout
        self.content = content()
    }

    var body: some View {
        SectionContainer(style: .hero, accent: identity.accent, contentPadding: 24) {
            VStack(alignment: .leading, spacing: identity.subtitle == nil ? 14 : 18) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: identity.subtitle == nil ? 4 : 8) {
                        Text(identity.eyebrow.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(identity.accent)
                            .tracking(0.7)

                        Text(identity.title)
                            .font(.system(size: identity.subtitle == nil ? 34 : 30, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let subtitle = identity.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 8)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.badgeFill(identity.accent))
                        .frame(width: identity.subtitle == nil ? 58 : 54, height: identity.subtitle == nil ? 58 : 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.badgeStroke(identity.accent), lineWidth: 1)
                        )
                        .overlay {
                            Image(systemName: identity.iconName)
                                .font((identity.subtitle == nil ? Font.title2 : .title3).weight(.semibold))
                                .foregroundStyle(AppTheme.iconTint(identity.accent))
                        }
                }

                if !metrics.isEmpty {
                    metricsView
                }

                content
            }
        }
    }

    @ViewBuilder
    private var metricsView: some View {
        switch metricLayout {
        case .adaptive:
            if identity.subtitle == nil {
                HeroInlineMetricRow(
                    metrics: metrics.map { HeroInlineMetric(label: $0.label, value: $0.value, color: $0.color) }
                )
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        ForEach(metrics) { metric in
                            MetricChip(label: metric.label, value: metric.value, color: metric.color, iconName: metric.iconName)
                        }
                    }

                    VStack(spacing: 12) {
                        ForEach(metrics) { metric in
                            MetricChip(label: metric.label, value: metric.value, color: metric.color, iconName: metric.iconName)
                        }
                    }
                }
            }
        case .compactRow:
            HStack(spacing: 10) {
                ForEach(metrics) { metric in
                    CompactMetricChip(
                        label: metric.label,
                        value: metric.value,
                        color: metric.color,
                        iconName: metric.iconName
                    )
                }
            }
        }
    }
}

struct HeroInlineMetricRow: View {
    let metrics: [HeroInlineMetric]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(metrics) { metric in
                HStack(spacing: 6) {
                    Text(metric.value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Text(metric.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.prominentText(metric.color).opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppTheme.badgeFill(metric.color).opacity(0.72))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(AppTheme.badgeStroke(metric.color).opacity(0.65), lineWidth: 1)
                        )
                )
                .fixedSize(horizontal: true, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusBadge: View {
    let title: String
    let iconName: String
    let color: Color

    var body: some View {
        Label(title, systemImage: iconName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.prominentText(color))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.badgeFill(color))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppTheme.badgeStroke(color), lineWidth: 1)
                    )
            )
    }
}

struct MetricChip: View {
    let label: String
    let value: String
    let color: Color
    let iconName: String?

    init(label: String, value: String, color: Color, iconName: String? = nil) {
        self.label = label
        self.value = value
        self.color = color
        self.iconName = iconName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let iconName {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.badgeFill(color))
                            .frame(width: 28, height: 28)

                        Image(systemName: iconName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.iconTint(color))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AppTheme.prominentText(color))
                        .frame(width: 12, height: 12)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.prominentText(color))
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .background(
            AppTheme.cardBackground(style: .metric, accent: color)
        )
    }
}

struct CompactMetricChip: View {
    let label: String
    let value: String
    let color: Color
    let iconName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.iconTint(color))
                }

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
                .tracking(0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .background(
            AppTheme.cardBackground(style: .metric, accent: color)
        )
    }
}

struct ProgressStrip: View {
    let value: Double
    let total: Double
    let tint: Color
    let trackTint: Color

    init(value: Double, total: Double, tint: Color = AppTheme.accent, trackTint: Color = AppTheme.secondaryGroupedBackground) {
        self.value = value
        self.total = total
        self.tint = tint
        self.trackTint = trackTint
    }

    var body: some View {
        GeometryReader { geometry in
            let progress = total > 0 ? min(max(value / total, 0), 1) : 0

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(trackTint)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.82), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 10)
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        EmptyState(icon: icon, title: title, message: message)
    }
}

struct StudyActionButton: View {
    let title: String
    let icon: String?
    let tint: Color
    let isProminent: Bool

    init(title: String, icon: String? = nil, tint: Color = AppTheme.accent, isProminent: Bool = true) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.isProminent = isProminent
    }

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
            }

            Text(title)
                .font(.headline.weight(.semibold))
        }
        .foregroundStyle(isProminent ? Color.white : AppTheme.prominentText(tint))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
        .shadow(color: isProminent ? Color.black.opacity(0.07) : .clear, radius: 10, x: 0, y: 5)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
            .fill(isProminent ? AnyShapeStyle(tint) : AnyShapeStyle(AppTheme.elevatedSurface))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .stroke(
                        isProminent
                            ? LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [AppTheme.badgeStroke(tint), AppTheme.cardStroke.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
    }
}

struct InsetListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let detail: String?
    let detailColor: Color
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        detail: String? = nil,
        detailColor: Color = AppTheme.accent,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.detailColor = detailColor
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: subtitle == nil ? .center : .top, spacing: 14) {
            leading

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: subtitle == nil ? 2 : 6) {
                    Text(title)
                        .font((subtitle == nil ? Font.headline : .body).weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 10)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.prominentText(detailColor).opacity(0.92))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.badgeFill(detailColor).opacity(0.52))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(AppTheme.badgeStroke(detailColor).opacity(0.72), lineWidth: 1)
                                )
                        )
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                trailing
                    .fixedSize()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.cardBackground(style: .grouped)
        )
    }
}

struct ModuleTile<Accessory: View>: View {
    let title: String
    let subtitle: String?
    let iconName: String
    let accent: Color
    let detail: String?
    @ViewBuilder let accessory: Accessory

    init(
        title: String,
        subtitle: String? = nil,
        iconName: String,
        accent: Color = AppTheme.accent,
        detail: String? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.accent = accent
        self.detail = detail
        self.accessory = accessory()
    }

    var body: some View {
        SectionContainer(style: .standard, accent: accent) {
            VStack(alignment: .leading, spacing: detail == nil ? 0 : 12) {
                HStack(alignment: subtitle == nil ? .center : .top, spacing: 14) {
                    moduleIcon

                    VStack(alignment: .leading, spacing: subtitle == nil ? 2 : 6) {
                        Text(title)
                            .font((subtitle == nil ? Font.title3 : .headline).weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)

                        if let subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 0)

                    accessory
                        .fixedSize()
                }

                if let detail, !detail.isEmpty {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)

                        Text(detail)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.prominentText(accent).opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(AppTheme.badgeFill(accent).opacity(0.32))
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(AppTheme.badgeStroke(accent).opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
        }
    }

    private var moduleIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.badgeFill(accent))
                .frame(width: subtitle == nil ? 52 : 48, height: subtitle == nil ? 52 : 48)

            Image(systemName: iconName)
                .font((subtitle == nil ? Font.title2 : .title3).weight(.semibold))
                .foregroundStyle(AppTheme.iconTint(accent))
        }
    }
}

struct FilterChipGroup<Option: Hashable>: View {
    let options: [Option]
    let selectedOptions: Set<Option>
    let title: (Option) -> String
    let tint: (Option) -> Color
    let action: (Option) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selectedOptions.contains(option)
                    Button {
                        action(option)
                    } label: {
                        Text(title(option))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? tint(option) : AppTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(isSelected ? AppTheme.badgeFill(tint(option)) : AppTheme.elevatedSurface)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(isSelected ? AppTheme.badgeStroke(tint(option)) : AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ReviewRow: View {
    let title: String
    let subtitle: String
    let detail: String
    let color: Color

    var body: some View {
        InsetListRow(title: title, subtitle: subtitle) {
            Circle()
                .fill(AppTheme.badgeFill(color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .fill(AppTheme.prominentText(color))
                        .frame(width: 10, height: 10)
                )
        } trailing: {
            Text(detail)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.prominentText(color))
        }
    }
}

struct HomeHeroCard: View {
    let snapshot: DashboardSnapshot

    private var statusTitle: String {
        snapshot.dueCards > 0 ? "Review window open" : "On schedule"
    }

    private var statusIcon: String {
        snapshot.dueCards > 0 ? "clock.badge.exclamationmark.fill" : "checkmark.circle.fill"
    }

    private var statusColor: Color {
        snapshot.dueCards > 0 ? AppTheme.warning : AppTheme.success
    }

    var body: some View {
        HeroCard(
            eyebrow: "Primary Gouge",
            title: "Study sharper for every brief, sim, and flight.",
            subtitle: "Training state, review pressure, and next steps stay visible without burying you in detail."
        ) {
            HStack(alignment: .top) {
                StatusBadge(title: statusTitle, iconName: statusIcon, color: statusColor)
                Spacer()
            }

            HStack(spacing: 12) {
                MetricChip(label: "Phases", value: "\(snapshot.phases)", color: AppTheme.accent)
                MetricChip(label: "Events", value: "\(snapshot.events)", color: AppTheme.accent)
                MetricChip(label: "Due Now", value: "\(snapshot.dueCards)", color: AppTheme.warning)
            }
        }
    }
}

struct PhaseCard: View {
    let phase: Phase

    var body: some View {
        ModuleTile(
            title: phase.title,
            iconName: phase.iconName,
            accent: AppTheme.accent
        ) {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.top, 4)
        }
    }
}

struct CategoryCard: View {
    let category: StudyCategory

    var body: some View {
        PhaseDestinationCard(
            title: category.displayName,
            iconName: category.iconName,
            detail: "\(category.events.count) events"
        )
    }
}

struct PhaseDestinationCard: View {
    let title: String
    let subtitle: String?
    let iconName: String
    let detail: String?

    init(title: String, subtitle: String? = nil, iconName: String, detail: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.detail = detail
    }

    var body: some View {
        ModuleTile(
            title: title,
            subtitle: subtitle,
            iconName: iconName,
            accent: AppTheme.accent,
            detail: detail
        ) {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.top, 4)
        }
    }
}

struct EventCard: View {
    let event: Event
    let progress: EventProgressSnapshot
    let dueCards: Int

    var body: some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(event.code)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(event.title)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 10)

                    if progress.completedAt != nil {
                        StatusBadge(title: "Ready", iconName: "checkmark.circle.fill", color: AppTheme.success)
                    }
                }

                Text(event.summary)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)

                HStack(spacing: 12) {
                    MetricChip(label: "Tools", value: "\(event.availableToolCount)", color: AppTheme.accent)
                    MetricChip(label: "Due", value: "\(dueCards)", color: dueCards > 0 ? AppTheme.warning : AppTheme.success)
                }
            }
        }
    }
}

struct ToolCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let accent: Color

    var body: some View {
        InsetListRow(title: title, subtitle: subtitle) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.badgeFill(accent))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.iconTint(accent))
            }
        } trailing: {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.top, 3)
        }
    }
}

struct HomeTaskCard: View {
    let task: HomeTaskSnapshot

    var body: some View {
        ModuleTile(
            title: task.title,
            subtitle: task.detail,
            iconName: task.iconName,
            accent: AppTheme.accent,
            detail: task.eyebrow.uppercased()
        )
    }
}

struct ProgressSpotlightCard: View {
    let snapshot: HomeTabSnapshot

    var body: some View {
        HeroCard(
            eyebrow: "Progress pulse",
            title: snapshot.progressHeadline,
            subtitle: snapshot.progressDetail
        ) {
            HStack(spacing: 12) {
                MetricChip(label: "Completed", value: "\(snapshot.completedEvents)", color: AppTheme.accent)
                MetricChip(label: "Due Queue", value: "\(snapshot.dueCards)", color: AppTheme.warning)
                MetricChip(label: "Catalog", value: "\(snapshot.totalEvents)", color: AppTheme.accent)
            }
        }
    }
}

struct ReviewPromptCard: View {
    let prompt: HomeReviewPromptSnapshot

    var body: some View {
        SectionContainer(style: .standard, accent: AppTheme.warning) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(prompt.title, systemImage: prompt.iconName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    StatusBadge(title: prompt.cue, iconName: "clock.fill", color: AppTheme.warning)
                }

                Text(prompt.detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

struct QuestionOfDayCard: View {
    let snapshot: HomeTabSnapshot

    var body: some View {
        SectionContainer(style: .primary, accent: AppTheme.accent) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(snapshot.questionTitle.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .tracking(0.7)

                    Spacer()

                    StatusBadge(title: "Coming soon", iconName: "sparkles", color: AppTheme.accent)
                }

                Text(snapshot.questionPrompt)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(snapshot.questionHint)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

struct PlaceholderHeroCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let status: String
    let iconName: String
    let accent: Color

    var body: some View {
        HeroCard(eyebrow: eyebrow, title: title, subtitle: subtitle, accent: accent) {
            HStack {
                StatusBadge(title: status, iconName: iconName, color: accent)
                Spacer()
            }
        }
    }
}

struct RoadmapFeatureCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let accent: Color

    var body: some View {
        ModuleTile(
            title: title,
            subtitle: subtitle,
            iconName: iconName,
            accent: accent,
            detail: "Planned"
        )
    }
}

struct SharedResourceRibbon: View {
    let resources: [SharedResource]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: "Always relevant",
                title: "Shared foundations",
                subtitle: "EPs, pattern work, systems, and reusable references stay linked across phases without duplication."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(resources) { resource in
                        SectionContainer {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(resource.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .frame(maxWidth: 220, alignment: .leading)

                                Text(resource.summary)
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: 220, alignment: .leading)
                                    .lineLimit(3)
                            }
                        }
                        .frame(width: 240)
                    }
                }
            }
        }
    }
}
