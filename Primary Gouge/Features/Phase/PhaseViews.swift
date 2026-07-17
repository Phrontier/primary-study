import SwiftUI

struct PhaseDetailView: View {
    let phase: Phase
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    private var generalLibraryResources: [SharedResource] {
        appModel.phaseKnowledgeResources(for: phase)
    }

    private var generalLibraryVideos: [VideoAsset] {
        appModel.phaseKnowledgeVideos(for: phase)
    }

    private var generalLibraryVideoGroups: [VideoLibraryGroupSnapshot] {
        appModel.phaseKnowledgeVideoGroups(for: phase)
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
                    HeroInlineMetric(label: "Library", value: "\(generalLibraryResources.count + generalLibraryVideos.count)", color: phase.accentColor)
                ])
            }

            if !generalLibraryResources.isEmpty || !generalLibraryVideos.isEmpty {
                NavigationLink {
                    PhaseKnowledgeView(phase: phase, resources: generalLibraryResources, videoGroups: generalLibraryVideoGroups)
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
                        categoryDestination(for: category)
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

    @ViewBuilder
    private func categoryDestination(for category: StudyCategory) -> some View {
        switch category.kind {
        case .groundSchool:
            GroundSchoolCategoryView(phase: phase, category: category)
        case .sims, .flights:
            EventListView(phase: phase, category: category)
        }
    }
}

struct PhaseKnowledgeView: View {
    let phase: Phase
    let resources: [SharedResource]
    let videoGroups: [VideoLibraryGroupSnapshot]
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @EnvironmentObject private var videoDownloadStore: VideoDownloadStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    var body: some View {
        AppScrollScreen {
            SectionHeader(
                eyebrow: phase.title,
                title: "General Library",
                subtitle: nil,
                accent: AppTheme.domainColor(.library)
            )

            if !videoGroups.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(
                        eyebrow: "Videos",
                        title: "Watch and Review",
                        subtitle: nil
                    )

                    ForEach(videoGroups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(
                                eyebrow: "Category",
                                title: group.category.displayName,
                                subtitle: nil,
                                accent: AppTheme.domainColor(.videos)
                            )

                            ForEach(group.videos) { video in
                                NavigationLink {
                                    PremiumContentGate(requirement: .premium, title: video.title) {
                                        VideoDetailView(video: video)
                                    }
                                } label: {
                                    ToolCard(
                                        title: video.title,
                                        subtitle: videoSubtitle(video),
                                        icon: group.category.iconName,
                                        accent: AppTheme.domainColor(.videos),
                                        isPremiumLocked: !subscriptionStore.hasPremiumAccess
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            ForEach(resources) { resource in
                NavigationLink {
                    PremiumContentGate(requirement: .premium, title: resource.title) {
                        SharedResourceDetailView(resource: resource)
                    }
                } label: {
                    ToolCard(
                        title: resource.title,
                        subtitle: nil,
                        icon: resourceIconName(for: resource),
                        accent: resourceAccent(for: resource),
                        isPremiumLocked: !subscriptionStore.hasPremiumAccess
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

    private func videoSubtitle(_ video: VideoAsset) -> String? {
        switch videoDownloadStore.status(for: video) {
        case .available:
            return "Available offline"
        case let .downloading(progress):
            return "Downloading \(Int(progress * 100))%"
        case .failed:
            return "Download failed"
        case .notDownloaded:
            if let byteSize = video.byteSize {
                return ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)
            }
            return nil
        }
    }
}

struct EventListView: View {
    let phase: Phase
    let category: StudyCategory

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

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
                        dueCards: event.flashcardDecks.flatMap(\.cardIDs).filter { appModel.progress(for: $0).isDue }.count,
                        isPremiumLocked: ContentAccessPolicy.isLocked(
                            ContentAccessPolicy.requirement(for: event),
                            subscriptionStore: subscriptionStore
                        )
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

struct GroundSchoolCategoryView: View {
    let phase: Phase
    let category: StudyCategory

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    private var snapshot: GroundSchoolCategorySnapshot {
        appModel.groundSchoolSnapshot(for: category)
    }

    var body: some View {
        AppScrollScreen(bottomPadding: 40) {
            HeroCard(
                eyebrow: phase.title,
                title: category.displayName,
                subtitle: category.summary,
                accent: category.kind.domainColor
            ) {
                HeroInlineMetricRow(metrics: [
                    HeroInlineMetric(label: "Items", value: "\(snapshot.totalToolCount)", color: category.kind.domainColor),
                    HeroInlineMetric(label: "Tests", value: "\(snapshot.totalPracticeTestCount)", color: AppTheme.domainColor(.quizzes)),
                    HeroInlineMetric(label: "Sections", value: "\(snapshot.totalSectionCount)", color: AppTheme.domainColor(.resources))
                ])
            }

            if snapshot.isEmpty {
                EmptyStateCard(
                    icon: category.iconName,
                    title: "No Ground School Tools Yet",
                    message: "This category is ready for materials, notes, and practice tests as they are added."
                )
            } else {
                if !snapshot.coreTools.isEmpty {
                    groundSchoolSection(
                        eyebrow: "Ground school",
                        title: "Core Materials",
                        subtitle: nil,
                        tools: snapshot.coreTools
                    )
                }

                ForEach(snapshot.eventSections) { section in
                    groundSchoolSection(
                        eyebrow: section.event.code == section.event.displayTitle ? phase.title : section.event.code,
                        title: section.event.displayTitle,
                        subtitle: nil,
                        tools: section.tools
                    )
                }
            }
        }
        .detailNavigationChrome(title: category.displayName)
        .task {
            appModel.recordGroundSchoolCategoryOpened(phase: phase, category: category)
        }
        .onAppear {
            searchChrome.updateScope(.events(title: category.displayName, phaseID: phase.id, categoryID: category.id))
        }
    }

    @ViewBuilder
    private func groundSchoolSection(
        eyebrow: String,
        title: String,
        subtitle: String?,
        tools: [GroundSchoolToolSnapshot]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: eyebrow,
                title: title,
                subtitle: subtitle
            )

            ForEach(tools) { tool in
                NavigationLink {
                    PremiumContentGate(
                        requirement: ContentAccessPolicy.requirement(for: tool.event),
                        title: toolTitle(for: tool)
                    ) {
                        destination(for: tool)
                    }
                } label: {
                    ToolCard(
                        title: toolTitle(for: tool),
                        subtitle: nil,
                        icon: iconName(for: tool),
                        accent: accent(for: tool),
                        isPremiumLocked: ContentAccessPolicy.isLocked(
                            ContentAccessPolicy.requirement(for: tool.event),
                            subscriptionStore: subscriptionStore
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destination(for tool: GroundSchoolToolSnapshot) -> some View {
        switch tool.content {
        case let .document(document):
            DocumentPreviewScreen(document: document)
        case let .discussionItems(notes):
            NotesDetailView(
                notes: notes,
                eventTitle: tool.event.code,
                accent: AppTheme.domainColor(.discussionItems)
            )
        case let .systemsBrief(notes):
            NotesDetailView(
                notes: notes,
                eventTitle: tool.event.code,
                accent: AppTheme.domainColor(.resources)
            )
        case let .flashcardDeck(deck):
            FlashcardDeckView(event: tool.event, deck: deck)
        case let .practiceTest(bank):
            PracticeTestView(event: tool.event, bank: bank)
        case let .sharedResource(resource):
            SharedResourceDetailView(resource: resource)
        case let .video(video):
            VideoDetailView(video: video)
        }
    }

    private func toolTitle(for tool: GroundSchoolToolSnapshot) -> String {
        switch tool.content {
        case let .document(document):
            if document.kind == .briefingGuide {
                return "\(tool.event.code) Briefing Guide"
            }
            return document.title
        case .discussionItems:
            return "Discussion Items"
        case .systemsBrief:
            return "Systems Brief"
        case let .flashcardDeck(deck):
            return deck.title
        case let .practiceTest(bank):
            return bank.title
        case let .sharedResource(resource):
            return resource.title
        case let .video(video):
            return video.title
        }
    }

    private func iconName(for tool: GroundSchoolToolSnapshot) -> String {
        switch tool.content {
        case let .document(document):
            return document.kind == .briefingGuide ? "doc.richtext.fill" : "doc.text.fill"
        case .discussionItems:
            return "text.alignleft"
        case .systemsBrief:
            return "gearshape.2.fill"
        case .flashcardDeck:
            return "rectangle.stack.fill"
        case .practiceTest:
            return "checklist.checked"
        case .sharedResource:
            return "square.grid.2x2.fill"
        case .video:
            return "play.rectangle.fill"
        }
    }

    private func accent(for tool: GroundSchoolToolSnapshot) -> Color {
        switch tool.content {
        case .document:
            return AppTheme.domainColor(.documents)
        case .discussionItems:
            return AppTheme.domainColor(.discussionItems)
        case .systemsBrief:
            return AppTheme.domainColor(.resources)
        case .flashcardDeck:
            return AppTheme.domainColor(.flashcards)
        case .practiceTest:
            return AppTheme.domainColor(.quizzes)
        case let .sharedResource(resource):
            return resource.librarySection.domainColor
        case .video:
            return AppTheme.domainColor(.videos)
        }
    }
}
