import SwiftUI

struct PhaseDetailView: View {
    let phase: Phase
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    private var generalKnowledgeResources: [SharedResource] {
        appModel.phaseKnowledgeResources(for: phase)
    }

    var body: some View {
        AppScrollScreen {
            HeroCard(
                eyebrow: "Training phase",
                title: phase.title,
                subtitle: nil
            ) {
                HeroInlineMetricRow(metrics: [
                    HeroInlineMetric(label: "Categories", value: "\(phase.categories.count)", color: AppTheme.domainColor(.groundSchool)),
                    HeroInlineMetric(label: "Events", value: "\(phase.categories.flatMap(\.events).count)", color: AppTheme.domainColor(.flights)),
                    HeroInlineMetric(label: "References", value: "\(generalKnowledgeResources.count)", color: AppTheme.domainColor(.resources))
                ])
            }

            if !generalKnowledgeResources.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(
                        eyebrow: "Knowledge base",
                        title: "General knowledge",
                        subtitle: nil
                    )

                    NavigationLink {
                        PhaseKnowledgeView(phase: phase, resources: generalKnowledgeResources)
                    } label: {
                        PhaseDestinationCard(
                            title: "General Knowledge",
                            subtitle: nil,
                            iconName: "books.vertical.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Categories",
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
                            iconName: category.iconName
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollActivatedNavigationChrome(title: phase.title)
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
                title: "General knowledge",
                subtitle: nil
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
        .scrollActivatedNavigationChrome(title: "General Knowledge")
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
        .scrollActivatedNavigationChrome(title: category.displayName)
        .onAppear {
            searchChrome.updateScope(.events(title: category.displayName, phaseID: phase.id, categoryID: category.id))
        }
    }
}
