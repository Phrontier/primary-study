import SwiftUI

enum ContentAccessRequirement: Hashable {
    case free
    case premium

    var requiresPremium: Bool { self == .premium }
}

enum ContentAccessPolicy {
    static let freeEventIDs: Set<String> = [
        "contacts-groundschool-contacts-gs",
        "contacts-sims-fam2101",
        "contacts-sims-fam2102",
        "echo-contacts-groundschool-fam1301",
        "echo-contacts-sims-fam2101",
        "echo-contacts-sims-fam2102",
    ]

    static let freeLibraryHubIDs: Set<String> = [
        "emergency-reference-hub",
    ]

    static func requirement(forEventID eventID: String) -> ContentAccessRequirement {
        freeEventIDs.contains(eventID) ? .free : .premium
    }

    static func requirement(for event: Event) -> ContentAccessRequirement {
        requirement(forEventID: event.id)
    }

    static func requirement(forLibraryHubID hubID: String) -> ContentAccessRequirement {
        freeLibraryHubIDs.contains(hubID) ? .free : .premium
    }

    static func requirement(for destination: SearchDestination, in appModel: StudyAppModel) -> ContentAccessRequirement {
        switch destination {
        case let .event(phaseID, eventID):
            guard let event = appModel.event(phaseID: phaseID, eventID: eventID) else { return .premium }
            return requirement(for: event)
        case let .eventDeck(phaseID, eventID, _):
            guard let event = appModel.event(phaseID: phaseID, eventID: eventID) else { return .premium }
            return requirement(for: event)
        case let .libraryDeck(id):
            return requirement(forLibraryHubID: id)
        case .instructor, .phase, .category:
            return .free
        case .sharedResource, .video:
            return .premium
        }
    }

    static func isLocked(
        _ requirement: ContentAccessRequirement,
        subscriptionStore: SubscriptionStore
    ) -> Bool {
        requirement.requiresPremium && !subscriptionStore.hasPremiumAccess
    }
}

struct PremiumContentGate<Content: View>: View {
    let requirement: ContentAccessRequirement
    let title: String
    @ViewBuilder let content: Content

    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    var body: some View {
        if ContentAccessPolicy.isLocked(requirement, subscriptionStore: subscriptionStore) {
            MorePremiumView(snapshot: appModel.moreHubSnapshot, lockedFeatureTitle: title)
                .accessibilityIdentifier("premium-content-gate")
        } else {
            content
        }
    }
}
