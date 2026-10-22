import SwiftUI
import UIKit

/// Home A1 measurements. Keep these scoped until the fidelity pass is approved.
enum HomeTextRole {
    case eyebrow, greeting, section, featured, code, row, metadata, codeMetadata, caption, question, action, choice, badge, referenceTitle, referenceCaption

    var size: CGFloat {
        switch self {
        case .eyebrow, .metadata, .caption: 12
        case .greeting: 30
        case .section: 17
        case .featured: 23
        case .code, .codeMetadata: 11
        case .row: 16
        case .question: 19
        case .action: 14
        case .choice: 13
        case .badge: 10
        case .referenceTitle: 14
        case .referenceCaption: 11
        }
    }
    var lineHeight: CGFloat {
        switch self {
        case .eyebrow, .code: 19
        case .greeting: 35.5
        case .section: 20
        case .featured: 31.05
        case .row: 21.6
        case .metadata: 18
        case .caption: 16.8
        case .codeMetadata: 16.5
        case .question: 26.6
        case .action: 20
        case .choice: 22
        case .badge: 12
        case .referenceTitle: 17
        case .referenceCaption: 13
        }
    }
    var weight: Font.Weight {
        switch self {
        case .greeting, .section, .featured, .code, .row, .referenceTitle: .bold
        case .eyebrow, .action, .question, .badge: .semibold
        default: .regular
        }
    }
    var tracking: CGFloat {
        switch self {
        case .greeting: -1
        case .section, .referenceTitle: -0.3
        case .featured: -0.65
        case .code: 1.1
        case .row: -0.25
        case .question: -0.35
        default: 0
        }
    }
    var textStyle: Font.TextStyle {
        switch self {
        case .greeting: .largeTitle
        case .featured: .title2
        case .section, .row: .headline
        case .eyebrow, .code, .metadata, .codeMetadata, .caption, .badge: .caption
        default: .body
        }
    }
}

private struct HomeTypography: ViewModifier {
    let role: HomeTextRole
    @ScaledMetric private var size: CGFloat

    init(_ role: HomeTextRole) {
        self.role = role
        _size = ScaledMetric(wrappedValue: role.size, relativeTo: role.textStyle)
    }
    func body(content: Content) -> some View {
        let scale = size / role.size
        content.font(.system(size: size, weight: role.weight))
            .tracking(role.tracking * scale)
            .lineSpacing(max(0, role.lineHeight * scale - UIFont.systemFont(ofSize: size).lineHeight))
            .frame(minHeight: role.lineHeight * scale, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    func homeText(_ role: HomeTextRole) -> some View { modifier(HomeTypography(role)) }
}

struct HomeRecentRow: View {
    let item: HomeFocusTopicSnapshot
    @EnvironmentObject private var appModel: StudyAppModel

    private var event: Event? {
        switch item.destination {
        case let .event(phaseID, eventID), let .eventDeck(phaseID, eventID, _):
            appModel.event(phaseID: phaseID, eventID: eventID)
        default: nil
        }
    }
    private var detail: String {
        #if DEBUG
        if HomeA1Fixture.isEnabled { return "Discussion items" }
        #endif
        if case .eventDeck = item.destination { return "Flashcards" }
        return "Event overview"
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName).font(.system(size: 18, weight: .regular))
                .foregroundStyle(StudyDesign.blue).frame(width: 42, height: 42)
                .background(StudyDesign.color(0xE1EDF9, 0x243853), in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                if let event {
                    Text(event.code).homeText(.code).foregroundStyle(StudyDesign.blue)
                    Text(event.displayTitle).homeText(.row).padding(.vertical, 4)
                    Text(detail).homeText(.codeMetadata).foregroundStyle(StudyDesign.secondary)
                } else {
                    Text(item.title).homeText(.row).padding(.vertical, 4)
                    if let subtitle = item.subtitle { Text(subtitle).homeText(.caption).foregroundStyle(StudyDesign.secondary) }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "arrow.right").font(.system(size: 15, weight: .regular))
                .foregroundStyle(StudyDesign.color(0x6A7E95, 0xA9B5C7)).accessibilityHidden(true)
        }
        .foregroundStyle(StudyDesign.ink).padding(.vertical, 18)
        .overlay(alignment: .bottom) { Rectangle().fill(StudyDesign.line).frame(height: 1) }
        .contentShape(Rectangle())
    }
}

#if DEBUG
/// Display-only fixture: never writes sample activity or answers into progress storage.
enum HomeA1Fixture {
    static var isEnabled: Bool { AppLaunchEnvironment.isUITesting && ProcessInfo.processInfo.arguments.contains("--home-a1-fixture") }

    static func snapshot(in model: StudyAppModel) -> HomeScreenSnapshot {
        let events = model.studyManifest.phases.flatMap { phase in phase.categories.flatMap { category in category.events.map { (phase.id, $0) } } }
        func destination(_ code: String) -> SearchDestination? {
            events.first { $0.1.code == code }.map { .event(phaseID: $0.0, eventID: $0.1.id) }
        }
        let choices = ["the ground", "mountains", "1R8", "the freezing level"].enumerated().map { QuizChoice(id: ["a", "b", "c", "d"][$0.offset], text: $0.element) }
        let question = HomeQuestionDefinition(id: "home-a1-fixture", sourceQuestionID: "fixture", categoryID: "fixture",
            prompt: "The potential for lightning strikes increases near ____.", choices: choices, correctChoiceID: choices[3].id,
            answer: "the freezing level", topicIDs: [], difficulty: .foundational, isUniversal: true)
        return HomeScreenSnapshot(greeting: "Good evening", statusLine: "", personalizedLine: "",
            continueStudying: HomeContinueStudyingSnapshot(title: "Last opened: I2103", subtitle: "Approach Maneuver",
                detail: "Last opened · 52 minutes ago", actionTitle: "Resume", destination: destination("I2103"), isFallback: false,
                displayTitle: "Approach Maneuver", contextLabel: "I2103"),
            currentFocus: .empty, reviewDue: [], weakAreas: [],
            questionOfDay: HomeQuestionOfDaySnapshot(question: question, selectedChoiceID: nil, wasCorrect: nil),
            studyStreak: 4, flashcardsReviewedToday: 12,
            recentDestinations: [
                HomeFocusTopicSnapshot(subtitle: "Cockpit Familiarization", id: "a1-fam2101", title: "FAM2101", iconName: "book", destination: destination("FAM2101")),
                HomeFocusTopicSnapshot(subtitle: "Ground Emergencies", id: "a1-fam2102", title: "FAM2102", iconName: "book", destination: destination("FAM2102"))
            ])
    }
}
#endif
