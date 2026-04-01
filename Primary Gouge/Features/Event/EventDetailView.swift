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
        .navigationTitle(event.code)
        .navigationBarTitleDisplayMode(.inline)
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
                MetricChip(label: "Decks", value: "\(event.flashcardDecks.count)", color: AppTheme.accent)
                MetricChip(label: "Questions", value: "\(event.questionBanks.reduce(0) { $0 + $1.questions.count })", color: AppTheme.accent)
                MetricChip(label: "Docs", value: "\(appModel.sharedResources(for: event, placement: nil).count + appModel.supplementalDocuments(for: event).count)", color: AppTheme.accent)
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
                    subtitle: "Open the source material you want in hand before stepping through the rest of the event prep."
                )

                NavigationLink {
                    DocumentPreviewScreen(document: document)
                } label: {
                    ToolCard(
                        title: "\(event.code) Briefing Guide",
                        subtitle: document.summary,
                        icon: "doc.richtext.fill",
                        accent: AppTheme.accent
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
                subtitle: "Everything you need to brief, review, quiz, and rehearse this event without digging."
            )

            VStack(spacing: 12) {
                if let notes = event.studyNotes {
                    NavigationLink {
                        NotesDetailView(notes: notes, eventTitle: event.displayTitle)
                    } label: {
                        ToolCard(title: "Study notes", subtitle: notes.summary, icon: "text.alignleft", accent: AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(event.flashcardDecks) { deck in
                    NavigationLink {
                        FlashcardDeckView(event: event, deck: deck)
                    } label: {
                        ToolCard(
                            title: deck.title,
                            subtitle: deck.summary,
                            icon: "rectangle.stack.fill",
                            accent: AppTheme.warning
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(event.questionBanks) { bank in
                    NavigationLink {
                        PracticeTestView(event: event, bank: bank)
                    } label: {
                        ToolCard(title: bank.title, subtitle: bank.summary, icon: "checklist.checked", accent: AppTheme.success)
                    }
                    .buttonStyle(.plain)
                }

                if let script = appModel.assembledScript(for: event) {
                    NavigationLink {
                        ScriptDetailView(script: script)
                    } label: {
                        ToolCard(title: "Event script", subtitle: "Reusable calls and procedures assembled for this event.", icon: "waveform.path.ecg.rectangle", accent: AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(appModel.videos(for: event, placement: .primary)) { video in
                    NavigationLink {
                        VideoDetailView(video: video)
                    } label: {
                        ToolCard(title: video.title, subtitle: video.summary, icon: "play.rectangle.fill", accent: AppTheme.success)
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
                subtitle: "Cross-event tools and references that support the same knowledge without duplication."
            )

            ForEach(resources) { resource in
                NavigationLink {
                    SharedResourceDetailView(resource: resource)
                } label: {
                    ToolCard(
                        title: resource.title,
                        subtitle: resource.summary,
                        icon: "square.grid.2x2.fill",
                        accent: AppTheme.warning
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
                        subtitle: video.summary,
                        icon: "play.rectangle.fill",
                        accent: AppTheme.success
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
                subtitle: "Open supporting briefs, documents, and references linked to this event."
            )

            ForEach(documents) { document in
                NavigationLink {
                    DocumentPreviewScreen(document: document)
                } label: {
                    ToolCard(
                        title: document.title,
                        subtitle: document.kind.displayName + " • " + document.summary,
                        icon: "doc.text.fill",
                        accent: AppTheme.accent
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
                subtitle: "A quick framing pass before you dive into the detailed prep material."
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
                        InsetListRow(title: area, subtitle: "Key point to revisit before you brief or step.") {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .navigationTitle(eventTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ScriptDetailView: View {
    let script: EventScript

    var body: some View {
        AppScrollScreen(bottomPadding: 30) {
            HeroCard(
                eyebrow: "Event script",
                title: script.title,
                subtitle: "Deterministically assembled from shared comm-call and maneuver blocks."
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
                            InsetListRow(title: note, subtitle: "Supporting guidance for this script section.") {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Script")
        .navigationBarTitleDisplayMode(.inline)
    }
}
