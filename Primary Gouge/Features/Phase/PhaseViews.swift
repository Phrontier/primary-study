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
                subtitle: phase.summary
            ) {
                HStack(spacing: 12) {
                    MetricChip(label: "Categories", value: "\(phase.categories.count)", color: AppTheme.accent)
                    MetricChip(label: "Events", value: "\(phase.categories.flatMap(\.events).count)", color: AppTheme.accent)
                    MetricChip(label: "References", value: "\(generalKnowledgeResources.count)", color: AppTheme.accent)
                }
            }

            if !generalKnowledgeResources.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(
                        eyebrow: "Knowledge base",
                        title: "General knowledge",
                        subtitle: "Recurring references and phase-wide material that stays useful throughout \(phase.title)."
                    )

                    NavigationLink {
                        PhaseKnowledgeView(phase: phase, resources: generalKnowledgeResources)
                    } label: {
                        PhaseDestinationCard(
                            title: "General Knowledge",
                            subtitle: "Phase-wide references, key documents, and recurring study material.",
                            iconName: "books.vertical.fill",
                            detail: "\(generalKnowledgeResources.count) references"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Categories",
                    title: "Open the right training lane",
                    subtitle: "Each category keeps event prep grouped and easier to scan."
                )

                ForEach(phase.categories) { category in
                    NavigationLink {
                        EventListView(phase: phase, category: category)
                    } label: {
                        CategoryCard(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(phase.title)
        .navigationBarTitleDisplayMode(.inline)
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
                subtitle: "Phase-level references that stay useful across events."
            )

            ForEach(resources) { resource in
                NavigationLink {
                    SharedResourceDetailView(resource: resource)
                } label: {
                    ToolCard(
                        title: resource.title,
                        subtitle: resource.summary,
                        icon: resourceIconName(for: resource),
                        accent: resourceAccent(for: resource)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("General Knowledge")
        .navigationBarTitleDisplayMode(.inline)
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
        switch resource.librarySection {
        case .videos:
            return AppTheme.success
        case .eps:
            return AppTheme.danger
        case .limits:
            return AppTheme.warning
        case .nwc:
            return AppTheme.warning
        case .supplements:
            return AppTheme.accent
        }
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
                subtitle: "Every event hub keeps the prep tools, references, and review load for this category in one place."
            ) {
                HStack(spacing: 12) {
                    MetricChip(label: "Events", value: "\(category.events.count)", color: AppTheme.accent)
                    MetricChip(label: "Studied", value: "\(category.events.filter { appModel.eventProgress(for: $0.id).completedAt != nil }.count)", color: AppTheme.accent)
                }
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
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            searchChrome.updateScope(.events(title: category.displayName, phaseID: phase.id, categoryID: category.id))
        }
    }
}
