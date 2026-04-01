import SwiftUI
import Combine

extension SearchDestination {
    var owningTab: AppTab {
        switch self {
        case .instructor:
            return .instructors
        case .event,
             .sharedResource,
             .video,
             .phase,
             .category,
             .eventDeck,
             .libraryDeck:
            return .events
        }
    }
}

@MainActor
final class SearchChromeModel: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var searchScope: SearchScope = .home
    @Published var query = ""

    @Published private var homePath: [SearchDestination] = []
    @Published private var eventsPath: [SearchDestination] = []
    @Published private var instructorsPath: [SearchDestination] = []
    @Published private var morePath: [SearchDestination] = []
    @Published private var searchPath: [SearchDestination] = []

    func updateScope(_ scope: SearchScope) {
        searchScope = scope
    }

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
        searchScope = defaultScope(for: tab)
    }

    func openResult(_ item: SearchResultItem) {
        route(to: item.destination)
    }

    func route(to destination: SearchDestination) {
        let owner = destination.owningTab
        setPath([destination], for: owner)
        selectedTab = owner
        searchScope = defaultScope(for: owner)
        query = ""
    }

    func defaultScope(for tab: AppTab) -> SearchScope {
        switch tab {
        case .home, .more, .search:
            return .home
        case .events:
            return .events(title: "Events", phaseID: nil, categoryID: nil)
        case .instructors:
            return .instructors
        }
    }

    func path(for tab: AppTab) -> [SearchDestination] {
        switch tab {
        case .home:
            return homePath
        case .events:
            return eventsPath
        case .instructors:
            return instructorsPath
        case .more:
            return morePath
        case .search:
            return searchPath
        }
    }

    func setPath(_ path: [SearchDestination], for tab: AppTab) {
        switch tab {
        case .home:
            homePath = path
        case .events:
            eventsPath = path
        case .instructors:
            instructorsPath = path
        case .more:
            morePath = path
        case .search:
            searchPath = path
        }
    }
}

struct SearchTabView: View {
    @EnvironmentObject private var chrome: SearchChromeModel
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var reviewStore: InstructorReviewStore

    @FocusState private var isQueryFocused: Bool

    private var instructors: [Instructor] {
        reviewStore.fetchInstructorSummaries(searchText: "")
    }

    private var trimmedQuery: String {
        chrome.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sections: [SearchResultSectionSnapshot] {
        switch chrome.searchScope {
        case .home:
            return appModel.homeSearchSections(query: chrome.query, instructors: instructors)
        case let .events(_, phaseID, categoryID):
            return appModel.eventSearchSections(query: chrome.query, phaseID: phaseID, categoryID: categoryID)
        case .instructors:
            return appModel.instructorSearchSections(query: chrome.query, instructors: instructors)
        }
    }

    var body: some View {
        AppScrollScreen(topPadding: 12, bottomPadding: 36) {
            HeroCard(
                eyebrow: chrome.searchScope.emptyStateTitle,
                title: "Find what you need",
                subtitle: chrome.searchScope.emptyStateMessage
            ) {
                searchField
            }

            resultsBody
        }
        .onAppear {
            chrome.updateScope(.home)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isQueryFocused = true
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.textMuted)

            TextField(chrome.searchScope.prompt, text: $chrome.query)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isQueryFocused)

            if !chrome.query.isEmpty {
                Button {
                    chrome.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(searchFieldBackground)
    }

    @ViewBuilder
    private var resultsBody: some View {
        if trimmedQuery.isEmpty {
            EmptyStateCard(
                icon: "magnifyingglass",
                title: "Start with a keyword",
                message: "Use the field above to jump into events, instructor gouge, flashcard decks, videos, and shared references without digging through tabs."
            )
        } else if sections.isEmpty {
            EmptyStateCard(
                icon: "tray",
                title: "No matches found",
                message: "Try a broader term or switch back into Events or Instructors if you want a narrower search context."
            )
        } else {
            ForEach(sections) { section in
                SectionContainer(style: .grouped, accent: AppTheme.accent, contentPadding: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(section.section.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                            Button {
                                chrome.openResult(item)
                            } label: {
                                SearchResultRow(item: item)
                            }
                            .buttonStyle(.plain)

                            if index < section.items.count - 1 {
                                Divider()
                                    .overlay(AppTheme.cardStroke.opacity(0.9))
                                    .padding(.leading, 74)
                            }
                        }
                    }
                }
            }
        }
    }

    private var searchFieldBackground: some View {
        AppTheme.cardBackground(style: .grouped, accent: AppTheme.accent)
    }
}

struct SearchResultRow: View {
    let item: SearchResultItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.10))
                    .frame(width: 42, height: 42)

                Image(systemName: item.section.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(item.subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.top, 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct SearchDestinationView: View {
    let destination: SearchDestination

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var reviewStore: InstructorReviewStore

    var body: some View {
        switch destination {
        case let .event(phaseID, eventID):
            if let phase = appModel.phase(id: phaseID), let event = appModel.event(phaseID: phaseID, eventID: eventID) {
                EventDetailView(phase: phase, event: event)
            } else {
                missingDestination
            }
        case let .instructor(id):
            if let instructor = reviewStore.fetchInstructor(id: id) {
                InstructorReviewDetailView(instructor: instructor)
            } else {
                missingDestination
            }
        case let .sharedResource(id):
            if let resource = appModel.sharedResource(id: id) {
                SharedResourceDetailView(resource: resource)
            } else {
                missingDestination
            }
        case let .video(id):
            if let video = appModel.video(id: id) {
                VideoDetailView(video: video)
            } else {
                missingDestination
            }
        case let .phase(id):
            if let phase = appModel.phase(id: id) {
                PhaseDetailView(phase: phase)
            } else {
                missingDestination
            }
        case let .category(phaseID, categoryID):
            if let phase = appModel.phase(id: phaseID), let category = appModel.category(phaseID: phaseID, categoryID: categoryID) {
                EventListView(phase: phase, category: category)
            } else {
                missingDestination
            }
        case let .eventDeck(phaseID, eventID, deckID):
            if let phase = appModel.phase(id: phaseID),
               let context = appModel.eventDeckContext(phaseID: phaseID, eventID: eventID, deckID: deckID) {
                FlashcardDeckView(event: context.0, deck: context.1)
                    .environmentObject(appModel)
                    .environmentObject(reviewStore)
                    .navigationTitle(phase.title)
            } else {
                missingDestination
            }
        case let .libraryDeck(id):
            if let hub = appModel.libraryHub(id: id) {
                FlashcardDeckView(hub: hub)
            } else {
                missingDestination
            }
        }
    }

    private var missingDestination: some View {
        EmptyStateCard(
            icon: "exclamationmark.triangle.fill",
            title: "Result unavailable",
            message: "This item could not be opened from search right now."
        )
        .padding(20)
        .background(AppTheme.screenBackground.ignoresSafeArea())
    }
}
