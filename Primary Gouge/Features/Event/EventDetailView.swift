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
        ) {
            HStack(spacing: 12) {
                MetricChip(label: "Decks", value: "\(event.flashcardDecks.count)", color: AppTheme.domainColor(.flashcards))
                MetricChip(label: "Questions", value: "\(event.questionBanks.reduce(0) { $0 + $1.questions.count })", color: AppTheme.domainColor(.quizzes))
                MetricChip(label: "Docs", value: "\(appModel.sharedResources(for: event, placement: nil).count + appModel.supplementalDocuments(for: event).count)", color: AppTheme.domainColor(.documents))
            }
        }
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
                        NotesDetailView(notes: notes, eventTitle: event.displayTitle)
                    } label: {
                        ToolCard(title: "Study notes", subtitle: notes.summary, icon: "text.alignleft", accent: AppTheme.domainColor(.documents))
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

                if let script = appModel.assembledScript(for: event) {
                    NavigationLink {
                        ScriptDetailView(script: script)
                    } label: {
                        ToolCard(title: "Event script", subtitle: nil, icon: "waveform.path.ecg.rectangle", accent: AppTheme.domainColor(.documents))
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

            if event.studyNotes == nil && event.flashcardDecks.isEmpty && event.questionBanks.isEmpty && appModel.assembledScript(for: event) == nil && appModel.videos(for: event, placement: .primary).isEmpty {
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

    var body: some View {
        AppScrollScreen(bottomPadding: 30) {
            HeroCard(
                eyebrow: eventTitle,
                title: notes.headline,
                subtitle: notes.summary
            )

            SectionContainer {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(notes.focusAreas, id: \.self) { area in
                        InsetListRow(title: area) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: eventTitle)
    }
}

private struct ScriptDetailView: View {
    let script: EventScript

    var body: some View {
        AppScrollScreen(bottomPadding: 30) {
            HeroCard(
                eyebrow: "Event script",
                title: script.title,
                subtitle: nil
            )

            ForEach(script.sections) { section in
                SectionContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !script.notes.isEmpty {
                SectionContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Script notes")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        ForEach(script.notes, id: \.self) { note in
                            InsetListRow(title: note) {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
            }
        }
        .detailNavigationChrome(title: "Script")
    }
}
