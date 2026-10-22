import SwiftUI

struct EventDetailView: View {
    let phase: Phase
    let event: Event

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @EnvironmentObject private var videoDownloadStore: VideoDownloadStore

    var body: some View {
        PremiumContentGate(
            requirement: ContentAccessPolicy.requirement(for: event),
            title: "\(event.code) \(event.displayTitle)"
        ) {
            eventContent
        }
    }

    private var eventContent: some View {
        PilotPage {
            PilotBackHeader(title: event.categoryKind.displayName)
            hero

            if !event.overview.isEmpty || !event.summary.isEmpty {
                EventOverviewCard(overview: event.overview.isEmpty ? event.summary : event.overview)
            }

            toolSection

            briefingGuideSection

            let videos = appModel.videos(for: event, placement: nil)
            if !videos.isEmpty {
                relatedVideoSection(videos)
            }

            let resources = appModel.sharedResources(for: event, placement: nil)
            if !resources.isEmpty {
                sharedResourceSection(resources)
            }

            let supplementalDocuments = appModel.supplementalDocuments(for: event)
            if !supplementalDocuments.isEmpty {
                additionalDocumentsSection(supplementalDocuments)
            }
        }
        .pilotNavigation()
        .task {
            appModel.markEventViewed(event)
        }
        .onAppear {
            let categoryID = phase.categories.first(where: { $0.kind == event.categoryKind })?.id
            searchChrome.updateScope(.events(title: event.code, phaseID: phase.id, categoryID: categoryID))
        }
    }

    private var hero: some View {
        StudyHeading(eyebrow: event.code, title: event.displayTitle, pill: true)
            .padding(.bottom, 30)
            .overlay(alignment: .bottom) { Rectangle().fill(StudyDesign.line).frame(height: 1) }
            .padding(.bottom, 22)
    }

    private var briefingGuideSection: some View {
        let briefingGuide = appModel.briefingGuide(for: event)
        return VStack(alignment: .leading, spacing: 13) {
            if let document = briefingGuide {
                Text("Briefing guide").pilotText(.section).accessibilityAddTraits(.isHeader)

                NavigationLink {
                    DocumentPreviewScreen(document: document)
                } label: {
                    StudyDestinationRow(
                        title: "\(event.code) Briefing Guide",
                        subtitle: document.title,
                        iconName: "book",
                        accent: StudyDesign.amberInk,
                        highlight: StudyDesign.color(0xF8EEDC, 0x403018)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Study and rehearse").pilotText(.section).accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                if let notes = event.studyNotes {
                    NavigationLink {
                        NotesDetailView(
                            notes: notes,
                            eventTitle: event.code,
                            accent: StudyDesign.teal, eventDisplayTitle: event.displayTitle
                        )
                    } label: {
                        StudyDestinationRow(title: "Discussion Items", subtitle: "Read the key preparation material.", iconName: "book", accent: StudyDesign.teal, iconFill: StudyDesign.phaseFill("vnav"))
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
                        StudyDestinationRow(
                            title: "Systems Brief",
                            subtitle: nil,
                            iconName: "gearshape.2.fill",
                            accent: AppTheme.domainColor(.resources)
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(event.flashcardDecks) { deck in
                    NavigationLink {
                        FlashcardDeckView(event: event, deck: deck)
                    } label: {
                        StudyDestinationRow(
                            title: event.flashcardDecks.count == 1 ? "Flashcards" : deck.title,
                            subtitle: "Practice the discussion items.",
                            iconName: "book",
                            accent: StudyDesign.purple, iconFill: StudyDesign.phaseFill("instruments"), separator: false
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(event.questionBanks) { bank in
                    NavigationLink {
                        PracticeTestView(event: event, bank: bank)
                    } label: {
                        StudyDestinationRow(title: bank.title, subtitle: nil, iconName: "checklist.checked", accent: AppTheme.domainColor(.quizzes))
                    }
                    .buttonStyle(.plain)
                }
            }

            if event.studyNotes == nil && event.systemsBrief == nil && event.flashcardDecks.isEmpty && event.questionBanks.isEmpty {
                EmptyStateCard(
                    icon: "tray",
                    title: "No Event Tools Yet",
                    message: "This event already carries source documents and can be expanded later by editing the generated study manifest."
                )
            }
        }.padding(.bottom, 22)
    }

    private func sharedResourceSection(_ resources: [SharedResource]) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(
                eyebrow: "Shared references",
                title: "Always-Relevant Material",
                subtitle: nil
            )

            ForEach(resources) { resource in
                NavigationLink {
                    SharedResourceDetailView(resource: resource)
                } label: {
                    StudyDestinationRow(
                        title: resource.title,
                        subtitle: nil,
                        iconName: "square.grid.2x2.fill",
                        accent: resource.librarySection.domainColor
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func relatedVideoSection(_ videos: [VideoAsset]) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(
                eyebrow: "Videos",
                title: "Related Videos",
                subtitle: nil
            )

            ForEach(videos) { video in
                NavigationLink {
                    VideoDetailView(video: video)
                } label: {
                    StudyDestinationRow(
                        title: video.title,
                        subtitle: videoSubtitle(video),
                        iconName: "play.rectangle.fill",
                        accent: AppTheme.domainColor(.videos)
                    )
                }
                .buttonStyle(.plain)
            }
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

    private func additionalDocumentsSection(_ documents: [SourceDocument]) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(
                eyebrow: "Documents",
                title: "Additional Source Material",
                subtitle: nil
            )

            ForEach(documents) { document in
                NavigationLink {
                    DocumentPreviewScreen(document: document)
                } label: {
                    StudyDestinationRow(
                        title: document.title,
                        subtitle: nil,
                        iconName: "doc.text.fill",
                        accent: StudyDesign.amberInk,
                        highlight: StudyDesign.amberFill
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
        VStack(alignment: .leading, spacing: 13) {
            Text("Overview").pilotText(.section).accessibilityAddTraits(.isHeader)
            Text(overview).pilotText(.overview).foregroundStyle(StudyDesign.reading)
                .padding(.leading, 18)
                .overlay(alignment: .leading) { Rectangle().fill(StudyDesign.blue).frame(width: 3) }
        }.padding(.bottom, 22)
    }
}

struct NotesDetailView: View {
    let notes: EventStudyNotes
    let eventTitle: String
    let accent: Color
    var eventDisplayTitle: String? = nil

    var body: some View {
        PilotPage {
            PilotBackHeader(title: eventTitle)
            StudyHeading(title: notes.headline, subtitle: eventDisplayTitle)
                .padding(.bottom, 20)
                .overlay(alignment: .bottom) { Rectangle().fill(StudyDesign.line).frame(height: 1) }
                .padding(.bottom, 22)

            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(notes.sections.enumerated()), id: \.offset) { _, section in
                    NotesDiscussionSectionView(section: section, accent: accent)
                }
            }
        }
        .pilotNavigation()
    }
}

private struct NotesDiscussionSectionView: View {
    let section: EventStudyNotesSection
    let accent: Color
    @State private var isExpanded = true
    private var title: String {
        guard let title = section.title, !title.isEmpty else { return "Discussion items" }
        return title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(title)
                        .pilotText(.readingHeading).foregroundStyle(StudyDesign.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 16)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold)).foregroundStyle(StudyDesign.secondary).frame(width: 13)
                }
                .padding(.leading, 15).frame(minHeight: 44)
                .overlay(alignment: .leading) { Rectangle().fill(accent).frame(width: 3) }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Collapse this section" : "Expand this section")
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        NotesDiscussionItemView(item: item, level: 0, accent: accent)
                    }
                }.padding(.leading, 8)
            }
        }
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) { Rectangle().fill(StudyDesign.line).frame(height: 1) }
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
                    .fill(level == 0 ? accent : StudyDesign.secondary)
                    .frame(width: 4, height: 4)
                    .padding(.top, 9)

                Text(item.text)
                    .pilotText(.body)
                    .foregroundStyle(StudyDesign.reading)
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
