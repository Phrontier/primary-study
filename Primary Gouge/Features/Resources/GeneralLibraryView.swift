import SwiftUI

struct GeneralLibraryView: View {
    let hubs: [LibraryStudyHub]
    let resourceGroups: [SharedResourceGroupSnapshot]
    let videoGroups: [VideoLibraryGroupSnapshot]

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @EnvironmentObject private var videoDownloadStore: VideoDownloadStore

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

            if !videoGroups.isEmpty {
                librarySection(
                    eyebrow: "Videos",
                    title: "Watch and review",
                    subtitle: nil
                ) {
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
                                    VideoDetailView(video: video)
                                } label: {
                                    ToolCard(
                                        title: video.title,
                                        subtitle: videoSubtitle(video),
                                        icon: group.category.iconName,
                                        accent: AppTheme.domainColor(.videos)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
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
