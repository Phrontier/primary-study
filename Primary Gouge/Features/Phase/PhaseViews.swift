import SwiftUI

struct PhaseDetailView: View {
    let phase: Phase
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    private var generalLibraryResources: [SharedResource] {
        appModel.phaseKnowledgeResources(for: phase)
    }

    var body: some View {
        AppScrollScreen {
            HeroCard(
                eyebrow: "Training phase",
                title: phase.title,
                subtitle: nil,
                accent: phase.accentColor
            ) {
                HeroInlineMetricRow(metrics: [
                    HeroInlineMetric(label: "Categories", value: "\(phase.categories.count)", color: phase.accentColor),
                    HeroInlineMetric(label: "Events", value: "\(phase.categories.flatMap(\.events).count)", color: phase.accentColor),
                    HeroInlineMetric(label: "References", value: "\(generalLibraryResources.count)", color: phase.accentColor)
                ])
            }

            if !generalLibraryResources.isEmpty {
                NavigationLink {
                    PhaseKnowledgeView(phase: phase, resources: generalLibraryResources)
                } label: {
                    PhaseDestinationCard(
                        title: "General Library",
                        subtitle: nil,
                        iconName: "books.vertical.fill",
                        accent: AppTheme.domainColor(.library)
                    )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Training blocks",
                    title: "Categories",
                    subtitle: nil
                )

                ForEach(phase.categories) { category in
                    NavigationLink {
                        EventListView(phase: phase, category: category)
                    } label: {
                        PhaseDestinationCard(
                            title: category.displayName,
                            subtitle: nil,
                            iconName: category.iconName,
                            accent: category.kind.domainColor
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .detailNavigationChrome(title: phase.title)
        .onAppear {
            searchChrome.updateScope(.events(title: phase.title, phaseID: phase.id, categoryID: nil))
        }
    }
}

struct PhaseKnowledgeView: View {
    let phase: Phase
    let resources: [SharedResource]
    @EnvironmentObject private var searchChrome: SearchChromeModel

    var body: some View {
        AppScrollScreen {
            SectionHeader(
                eyebrow: phase.title,
                title: "General Library",
                subtitle: nil,
                accent: AppTheme.domainColor(.library)
            )

            ForEach(resources) { resource in
                NavigationLink {
                    SharedResourceDetailView(resource: resource)
                } label: {
                    ToolCard(
                        title: resource.title,
                        subtitle: nil,
                        icon: resourceIconName(for: resource),
                        accent: resourceAccent(for: resource)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .detailNavigationChrome(title: "General Library")
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    private func resourceIconName(for resource: SharedResource) -> String {
        switch resource.librarySection {
        case .videos:
            return "play.rectangle.fill"
        case .eps:
            return "exclamationmark.shield.fill"
        case .limits:
            return "gauge.with.dots.needle.bottom.50percent"
        case .nwc:
            return "triangle.fill"
        case .supplements:
            return "square.grid.2x2.fill"
        }
    }

    private func resourceAccent(for resource: SharedResource) -> Color {
        resource.librarySection.domainColor
    }
}

struct EventListView: View {
    let phase: Phase
    let category: StudyCategory

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    var body: some View {
        AppScrollScreen {
            HeroCard(
                eyebrow: phase.title,
                title: category.displayName,
                subtitle: nil
            ) {
                HeroInlineMetricRow(metrics: [
                    HeroInlineMetric(label: "Events", value: "\(category.events.count)", color: category.kind.domainColor),
                    HeroInlineMetric(label: "Studied", value: "\(category.events.filter { appModel.eventProgress(for: $0.id).completedAt != nil }.count)", color: AppTheme.statusColor(.success))
                ])
            }

            ForEach(category.events) { event in
                NavigationLink {
                    EventDetailView(phase: phase, event: event)
                } label: {
                    EventCard(
                        event: event,
                        progress: appModel.eventProgress(for: event.id),
                        dueCards: event.flashcardDecks.flatMap(\.cardIDs).filter { appModel.progress(for: $0).isDue }.count
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .detailNavigationChrome(title: category.displayName)
        .onAppear {
            searchChrome.updateScope(.events(title: category.displayName, phaseID: phase.id, categoryID: category.id))
        }
    }
}
