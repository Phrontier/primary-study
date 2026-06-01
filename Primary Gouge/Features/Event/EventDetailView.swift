import SwiftUI

struct EventDetailView: View {
    let phase: Phase
    let event: Event

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel

    var body: some View {
        AppScrollScreen(bottomPadding: 40) {
            hero

            EventOverviewCard(overview: event.overview)

            briefingGuideSection

            toolSection

            let resources = appModel.sharedResources(for: event, placement: nil)
            if !resources.isEmpty {
                sharedResourceSection(resources)
            }

            let supplementalDocuments = appModel.supplementalDocuments(for: event)
            if !supplementalDocuments.isEmpty {
                additionalDocumentsSection(supplementalDocuments)
            }
        }
        .detailNavigationChrome(title: event.code)
        .task {
            appModel.markEventViewed(event)
        }
        .onAppear {
            let categoryID = phase.categories.first(where: { $0.kind == event.categoryKind })?.id
            searchChrome.updateScope(.events(title: event.code, phaseID: phase.id, categoryID: categoryID))
        }
    }

    private var hero: some View {
        HeroCard(
            eyebrow: "\(phase.title) • \(event.categoryKind.displayName)",
            title: event.displayTitle,
            subtitle: event.summary
        )
    }

    private var briefingGuideSection: some View {
        let briefingGuide = appModel.briefingGuide(for: event)
        return VStack(alignment: .leading, spacing: 14) {
            if let document = briefingGuide {
                SectionHeader(
                    eyebrow: "Start here",
                    title: "Briefing guide",
                    subtitle: nil
                )

                NavigationLink {
                    DocumentPreviewScreen(document: document)
                } label: {
                    ToolCard(
                        title: "\(event.code) Briefing Guide",
                        subtitle: nil,
                        icon: "doc.richtext.fill",
                        accent: AppTheme.domainColor(.documents)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: "Prep tools",
                title: "Study and rehearse",
                subtitle: nil
            )

            VStack(spacing: 12) {
                if let notes = event.studyNotes {
                    NavigationLink {
                        NotesDetailView(
                            notes: notes,
                            eventTitle: event.code,
                            accent: AppTheme.domainColor(.discussionItems)
                        )
                    } label: {
                        ToolCard(title: "Discussion items", subtitle: nil, icon: "text.alignleft", accent: AppTheme.domainColor(.discussionItems))
                    }
                    .buttonStyle(.plain)
                }

                if let systemsBrief = event.systemsBrief {
                    NavigationLink {
                        NotesDetailView(
                            notes: systemsBrief,
                            eventTitle: event.code,
                            accent: AppTheme.domainColor(.resources)
                        )
                    } label: {
                        ToolCard(
                            title: "Systems brief",
                            subtitle: nil,
                            icon: "gearshape.2.fill",
                            accent: AppTheme.domainColor(.resources)
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(event.flashcardDecks) { deck in
                    NavigationLink {
                        FlashcardDeckView(event: event, deck: deck)
                    } label: {
                        ToolCard(
                            title: deck.title,
                            subtitle: nil,
                            icon: "rectangle.stack.fill",
                            accent: AppTheme.domainColor(.flashcards)
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(event.questionBanks) { bank in
                    NavigationLink {
                        PracticeTestView(event: event, bank: bank)
                    } label: {
                        ToolCard(title: bank.title, subtitle: nil, icon: "checklist.checked", accent: AppTheme.domainColor(.quizzes))
                    }
                    .buttonStyle(.plain)
                }

                ForEach(appModel.videos(for: event, placement: .primary)) { video in
                    NavigationLink {
                        VideoDetailView(video: video)
                    } label: {
                        ToolCard(title: video.title, subtitle: nil, icon: "play.rectangle.fill", accent: AppTheme.domainColor(.videos))
                    }
                    .buttonStyle(.plain)
                }
            }

            if event.studyNotes == nil && event.systemsBrief == nil && event.flashcardDecks.isEmpty && event.questionBanks.isEmpty && appModel.videos(for: event, placement: .primary).isEmpty {
                EmptyStateCard(
                    icon: "tray",
                    title: "No event tools yet",
                    message: "This event already carries source documents and can be expanded later by editing the generated study manifest."
                )
            }
        }
    }

    private func sharedResourceSection(_ resources: [SharedResource]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: "Shared references",
                title: "Always-relevant material",
                subtitle: nil
            )

            ForEach(resources) { resource in
                NavigationLink {
                    SharedResourceDetailView(resource: resource)
                } label: {
                    ToolCard(
                        title: resource.title,
                        subtitle: nil,
                        icon: "square.grid.2x2.fill",
                        accent: resource.librarySection.domainColor
                    )
                }
                .buttonStyle(.plain)
            }

            ForEach(appModel.videos(for: event, placement: .supplemental)) { video in
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

    private func additionalDocumentsSection(_ documents: [SourceDocument]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: "Documents",
                title: "Additional source material",
                subtitle: nil
            )

            ForEach(documents) { document in
                NavigationLink {
                    DocumentPreviewScreen(document: document)
                } label: {
                    ToolCard(
                        title: document.title,
                        subtitle: nil,
                        icon: "doc.text.fill",
                        accent: AppTheme.domainColor(.documents)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct EventOverviewCard: View {
    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                eyebrow: "Overview",
                title: "What this event is about",
                subtitle: nil
            )

            SectionContainer {
                Text(overview)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct NotesDetailView: View {
    let notes: EventStudyNotes
    let eventTitle: String
    let accent: Color

    var body: some View {
        AppScrollScreen(bottomPadding: 30) {
            SectionHeader(
                eyebrow: eventTitle,
                title: notes.headline,
                subtitle: nil,
                accent: accent
            )

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(notes.sections.enumerated()), id: \.offset) { _, section in
                    NotesDiscussionSectionView(section: section, accent: accent)
                }
            }
        }
        .detailNavigationChrome(title: eventTitle)
    }
}

private struct NotesDiscussionSectionView: View {
    let section: EventStudyNotesSection
    let accent: Color

    var body: some View {
        SectionContainer(accent: accent) {
            VStack(alignment: .leading, spacing: 16) {
                if let title = section.title, !title.isEmpty {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        NotesDiscussionItemView(item: item, level: 0, accent: accent)
                    }
                }
            }
        }
    }
}

private struct NotesDiscussionItemView: View {
    let item: EventStudyNotesItem
    let level: Int
    let accent: Color

    private var childItems: [EventStudyNotesItem] {
        item.children ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(level == 0 ? accent : AppTheme.cardStroke)
                    .frame(width: level == 0 ? 7 : 5, height: level == 0 ? 7 : 5)
                    .padding(.top, 7)

                Text(item.text)
                    .font(level == 0 ? .body.weight(.medium) : .subheadline)
                    .foregroundStyle(level == 0 ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !childItems.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(childItems.enumerated()), id: \.offset) { _, child in
                        NotesDiscussionItemView(item: child, level: level + 1, accent: accent)
                    }
                }
                .padding(.leading, 22)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.cardStroke.opacity(0.85))
                        .frame(width: 1)
                        .padding(.leading, 9)
                }
            }
        }
    }
}
