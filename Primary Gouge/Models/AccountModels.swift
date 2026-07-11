import Foundation

enum AccountPermission: String, Codable, CaseIterable, Hashable, Identifiable {
    case instructorGougeModerator = "instructor_gouge_moderator"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instructorGougeModerator:
            return "Instructor Gouge Moderator"
        }
    }
}

enum AccountAuthMethod: String, Codable, CaseIterable, Hashable, Identifiable {
    case apple
    case emailPassword = "email_password"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple:
            return "Sign in with Apple"
        case .emailPassword:
            return "Verified Email"
        }
    }
}

enum SyllabusTrack: String, Codable, CaseIterable, Hashable, Identifiable {
    case delta
    case echo
    case notSure = "not_sure"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .delta:
            return "Delta"
        case .echo:
            return "Echo"
        case .notSure:
            return "Not Sure Yet"
        }
    }

    var contentFallback: SyllabusTrack {
        switch self {
        case .delta:
            return .delta
        case .echo, .notSure:
            return .echo
        }
    }
}

struct AccountProfile: Codable, Hashable, Identifiable {
    let id: String
    var displayName: String?
    var email: String?
    var emailVerified: Bool
    var authMethods: [AccountAuthMethod]?
    var squadronID: String?
    var syllabusID: SyllabusTrack?
    var permissions: [AccountPermission]
    var profileComplete: Bool

    static let notSureSquadronID = "not_sure"

    var displayTitle: String {
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        if let email, !email.isEmpty {
            return email
        }
        return "Primary Gouge Account"
    }

    var selectedSyllabus: SyllabusTrack {
        syllabusID ?? .notSure
    }

    var usesAppleSignIn: Bool {
        authMethods?.contains(.apple) == true
    }

    func hasPermission(_ permission: AccountPermission) -> Bool {
        permissions.contains(permission)
    }

    static func squadronTitle(for id: String?) -> String {
        guard let id, !id.isEmpty else { return "Not Set" }
        if id == notSureSquadronID {
            return "Not Sure Yet"
        }
        return InstructorReviewSeedData.squadron(for: id).displayName
    }

    static func normalizedProfileSquadronID(_ id: String?) -> String {
        guard
            let id,
            !id.isEmpty,
            id != notSureSquadronID,
            TrainingWingID.parentWingID(forSquadronID: id) != nil
        else {
            return notSureSquadronID
        }

        return id
    }
}

struct AccountSession: Codable, Hashable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var profile: AccountProfile

    var accessTokenIsExpired: Bool {
        expiresAt <= Date()
    }
}

enum AccountPhase: Hashable {
    case loading
    case signedOut
    case signedIn
}
