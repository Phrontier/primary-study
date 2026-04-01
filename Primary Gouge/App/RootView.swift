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

    private var headerIdentity: TabHeaderIdentity {
        TabHeaderIdentity(
            navigationTitle: "Events",
            eyebrow: "Event center",
            title: "Open your next event",
            subtitle: nil,
            iconName: AppTab.events.iconName,
            accent: AppTheme.domainColor(.flights)
        )
    }

    var body: some View {
        AppScrollScreen {
            TabHeaderCard(
                identity: headerIdentity,
                metrics: [
                    TabHeaderMetric(
                        label: "Phases",
                        value: "\(appModel.studyManifest.phases.count)",
                        color: AppTheme.domainColor(.groundSchool),
                        iconName: "square.grid.2x2.fill"
                    ),
                    TabHeaderMetric(
                        label: "Library",
                        value: "\(appModel.generalLibraryStudyHubs.count)",
                        color: AppTheme.domainColor(.library),
                        iconName: "books.vertical.fill"
                    ),
                    TabHeaderMetric(
                        label: "Videos",
                        value: "\(appModel.generalLibraryVideos.count)",
                        color: AppTheme.domainColor(.videos),
                        iconName: "play.rectangle.fill"
                    )
                ]
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
                        subtitle: nil,
                        icon: "books.vertical.fill",
                        accent: AppTheme.domainColor(.library)
                    )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    eyebrow: "Training pipeline",
                    title: "Choose your phase",
                    subtitle: nil
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
        .scrollActivatedNavigationChrome(title: headerIdentity.navigationTitle)
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
                        subtitle: nil
                    )

                    ForEach(hubs) { hub in
                        VStack(alignment: .leading, spacing: 12) {
                            NavigationLink {
                                FlashcardDeckView(hub: hub)
                            } label: {
                                ToolCard(
                                    title: hub.deck.title,
                                    subtitle: nil,
                                    icon: "rectangle.stack.fill.badge.person.crop",
                                    accent: AppTheme.domainColor(.flashcards)
                                )
                            }
                            .buttonStyle(.plain)

                            ForEach(appModel.resources(for: hub)) { resource in
                                NavigationLink {
                                    SharedResourceDetailView(resource: resource)
                                } label: {
                                    ToolCard(
                                        title: generalLibraryTitle(for: resource),
                                        subtitle: nil,
                                        icon: "doc.richtext.fill",
                                        accent: resource.librarySection.domainColor
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
                    subtitle: nil
                ) {
                    ForEach(videos) { video in
                        NavigationLink {
                            VideoDetailView(video: video)
                        } label: {
                            ToolCard(title: video.title, subtitle: nil, icon: "play.rectangle.fill", accent: AppTheme.domainColor(.videos))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(resourceGroups) { group in
                librarySection(
                    eyebrow: "References",
                    title: group.section.displayName,
                    subtitle: nil
                ) {
                    ForEach(group.resources) { resource in
                        NavigationLink {
                            SharedResourceDetailView(resource: resource)
                        } label: {
                            ToolCard(title: resource.title, subtitle: nil, icon: iconName(for: group.section), accent: accent(for: group.section))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .scrollActivatedNavigationChrome(title: "General Library")
        .onAppear {
            searchChrome.updateScope(.home)
        }
    }

    @ViewBuilder
    private func librarySection<Content: View>(
        eyebrow: String,
        title: String,
        subtitle: String? = nil,
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
        section.domainColor
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
}
