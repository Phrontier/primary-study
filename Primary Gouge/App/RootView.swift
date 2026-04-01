import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case events
    case instructors
    case more
    case search

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .events: "Events"
        case .instructors: "Instructors"
        case .more: "More"
        case .search: "Search"
        }
    }

    var iconName: String {
        switch self {
        case .home: "house.fill"
        case .events: "calendar"
        case .instructors: "person.2.crop.square.stack.fill"
        case .more: "ellipsis.circle.fill"
        case .search: "magnifyingglass"
        }
    }
}

struct RootView: View {
    @StateObject private var searchChrome = SearchChromeModel()

    var body: some View {
        TabView(selection: tabSelection) {
            TabNavigationHost(path: pathBinding(for: .home)) {
                HomeTabView()
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.iconName)
            }
            .tag(AppTab.home)

            TabNavigationHost(path: pathBinding(for: .events)) {
                EventsTabView()
            }
            .tabItem {
                Label(AppTab.events.title, systemImage: AppTab.events.iconName)
            }
            .tag(AppTab.events)

            TabNavigationHost(path: pathBinding(for: .instructors)) {
                InstructorsTabView()
            }
            .tabItem {
                Label(AppTab.instructors.title, systemImage: AppTab.instructors.iconName)
            }
            .tag(AppTab.instructors)

            TabNavigationHost(path: pathBinding(for: .more)) {
                MoreTabView()
            }
            .tabItem {
                Label(AppTab.more.title, systemImage: AppTab.more.iconName)
            }
            .tag(AppTab.more)

            TabNavigationHost(path: pathBinding(for: .search)) {
                SearchTabView()
            }
            .tabItem {
                Label(AppTab.search.title, systemImage: AppTab.search.iconName)
            }
            .tag(AppTab.search)
        }
        .tint(AppTheme.accent)
        .environmentObject(searchChrome)
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { searchChrome.selectedTab },
            set: { searchChrome.selectTab($0) }
        )
    }

    private func pathBinding(for tab: AppTab) -> Binding<[SearchDestination]> {
        Binding(
            get: { searchChrome.path(for: tab) },
            set: { searchChrome.setPath($0, for: tab) }
        )
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(StudyAppModel.preview)
            .environmentObject(InstructorReviewStore())
            .environmentObject(QuizStore())
    }
}

private struct TabNavigationHost<Content: View>: View {
    @Binding var path: [SearchDestination]
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: SearchDestination.self) { destination in
                    SearchDestinationView(destination: destination)
                }
        }
    }
}

private struct HomeTabView: View {
    var body: some View {
        HomeScreenView()
    }
}

private struct EventsTabView: View {
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    var body: some View {
        AppScrollScreen {
            HeroCard(
                eyebrow: "Event center",
                title: "Open your next event",
                subtitle: "General Library stays up front, and every phase still drills cleanly down into the event you are preparing for."
            )

            if !appModel.generalLibraryStudyHubs.isEmpty || !appModel.generalLibraryResources.isEmpty || !appModel.generalLibraryVideos.isEmpty {
                NavigationLink {
                    GeneralLibraryView(
                        hubs: appModel.generalLibraryStudyHubs,
                        resourceGroups: appModel.generalLibraryGroupedResources,
                        videos: appModel.generalLibraryVideos
                    )
                } label: {
                    ToolCard(
                        title: "General Library",
                        subtitle: "Cross-phase flashcards, EPs, limits, notes, warnings, cautions, videos, and recurring references.",
                        icon: "books.vertical.fill",
                        accent: AppTheme.accent
                    )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Training pipeline",
                    title: "Choose your phase",
                    subtitle: "Open your phase, grab the recurring references you need, and drop into the exact event hub you want."
                )

                ForEach(appModel.studyManifest.phases) { phase in
                    NavigationLink {
                        PhaseDetailView(phase: phase)
                    } label: {
                        PhaseCard(phase: phase)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            searchChrome.updateScope(.events(title: "Events", phaseID: nil, categoryID: nil))
        }
    }
}

private struct InstructorsTabView: View {
    var body: some View {
        InstructorReviewsRootView()
    }
}

private struct GeneralLibraryView: View {
    let hubs: [LibraryStudyHub]
    let resourceGroups: [SharedResourceGroupSnapshot]
    let videos: [VideoAsset]
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    var body: some View {
        AppScrollScreen(bottomPadding: 40) {
            if !hubs.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(
                        eyebrow: "Decks",
                        title: "Focused memory work",
                        subtitle: "Core decks and linked references that stay useful across phases."
                    )

                    ForEach(hubs) { hub in
                        VStack(alignment: .leading, spacing: 12) {
                            NavigationLink {
                                FlashcardDeckView(hub: hub)
                            } label: {
                                ToolCard(
                                    title: hub.deck.title,
                                    subtitle: hub.deck.summary,
                                    icon: "rectangle.stack.fill.badge.person.crop",
                                    accent: AppTheme.warning
                                )
                            }
                            .buttonStyle(.plain)

                            ForEach(appModel.resources(for: hub)) { resource in
                                NavigationLink {
                                    SharedResourceDetailView(resource: resource)
                                } label: {
                                    ToolCard(
                                        title: generalLibraryTitle(for: resource),
                                        subtitle: resource.summary,
                                        icon: "doc.richtext.fill",
                                        accent: AppTheme.accent
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            if !videos.isEmpty {
                librarySection(
                    eyebrow: "Videos",
                    title: "Watch and review",
                    subtitle: "Shared video content that supports multiple phases and events."
                ) {
                    ForEach(videos) { video in
                        NavigationLink {
                            VideoDetailView(video: video)
                        } label: {
                            ToolCard(title: video.title, subtitle: video.summary, icon: "play.rectangle.fill", accent: AppTheme.success)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(resourceGroups) { group in
                librarySection(
                    eyebrow: "References",
                    title: group.section.displayName,
                    subtitle: librarySubtitle(for: group.section)
                ) {
                    ForEach(group.resources) { resource in
                        NavigationLink {
                            SharedResourceDetailView(resource: resource)
                        } label: {
                            ToolCard(title: resource.title, subtitle: resource.summary, icon: iconName(for: group.section), accent: accent(for: group.section))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("General Library")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    @ViewBuilder
    private func librarySection<Content: View>(
        eyebrow: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(eyebrow: eyebrow, title: title, subtitle: subtitle)
            content()
        }
    }

    private func iconName(for section: SharedResourceSection) -> String {
        switch section {
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

    private func accent(for section: SharedResourceSection) -> Color {
        switch section {
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

    private func generalLibraryTitle(for resource: SharedResource) -> String {
        switch resource.id {
        case "ep-limits-key":
            return "EP / Limits Key"
        case "ep-nwcs-admin":
            return "EP N/W/C"
        default:
            return resource.title
        }
    }

    private func librarySubtitle(for section: SharedResourceSection) -> String {
        switch section {
        case .videos:
            return "Shared video study assets."
        case .eps:
            return "Emergency procedure references and memory refreshers."
        case .limits:
            return "Critical numbers and quick-limit study material."
        case .nwc:
            return "Notes, warnings, cautions, and recurring callouts."
        case .supplements:
            return "Other shared reference material that supports event prep."
        }
    }
}
