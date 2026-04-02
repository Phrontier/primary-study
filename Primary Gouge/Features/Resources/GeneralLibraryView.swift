import SwiftUI

struct GeneralLibraryView: View {
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
                            ToolCard(
                                title: video.title,
                                subtitle: nil,
                                icon: "play.rectangle.fill",
                                accent: AppTheme.domainColor(.videos)
                            )
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
                            ToolCard(
                                title: resource.title,
                                subtitle: nil,
                                icon: iconName(for: group.section),
                                accent: accent(for: group.section)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .detailNavigationChrome(title: "General Library")
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
