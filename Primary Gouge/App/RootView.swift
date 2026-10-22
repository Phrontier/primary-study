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
        #if DEBUG
        if AppLaunchEnvironment.isUITesting && ProcessInfo.processInfo.arguments.contains("--design-pattern-gallery") {
            DesignPatternGallery()
        } else {
            appTabs
        }
        #else
        appTabs
        #endif
    }

    private var appTabs: some View {
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
            .environmentObject(SubscriptionStore())
            .environmentObject(InstructorReviewStore())
            .environmentObject(QuizStore())
            .environmentObject(VideoDownloadStore())
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
        PilotPage {
            StudyHeading(title: "Events", subtitle: "Find your event. Prepare for what’s next.")
                .padding(.top, 7).padding(.bottom, 28)

            VStack(alignment: .leading, spacing: 0) {
                Text("Choose your phase").pilotText(.section).padding(.bottom, 8).accessibilityAddTraits(.isHeader)

                ForEach(appModel.studyManifest.phases) { phase in
                    NavigationLink {
                        PhaseDetailView(phase: phase)
                    } label: {
                        StudyDestinationRow(title: phase.title, iconName: StudyDesign.phaseIcon(phase.id), accent: StudyDesign.phaseAccent(phase.id), iconFill: StudyDesign.phaseFill(phase.id), layout: .root)
                    }
                    .buttonStyle(.plain)
                }
            }
            if !appModel.generalLibraryStudyHubs.isEmpty || !appModel.generalLibraryResources.isEmpty || !appModel.generalLibraryVideos.isEmpty {
                NavigationLink {
                    GeneralLibraryView(
                        hubs: appModel.generalLibraryStudyHubs,
                        resourceGroups: appModel.generalLibraryGroupedResources,
                        videoGroups: appModel.generalLibraryVideoGroups
                    )
                } label: {
                    StudyDestinationRow(
                        title: "General Library",
                        subtitle: "Reference material across your training.",
                        iconName: "book",
                        accent: StudyDesign.amberInk,
                        highlight: StudyDesign.color(0xF8EEDC, 0x403018),
                        layout: .library
                    )
                }
                .buttonStyle(.plain).padding(.top, 26)
            }
        }
        .pilotNavigation()
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
