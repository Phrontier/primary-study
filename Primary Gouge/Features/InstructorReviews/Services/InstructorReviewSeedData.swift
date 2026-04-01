import Foundation

struct InstructorReviewSeedItem: Codable, Hashable {
    let id: String
    let instructorName: String
    let squadronID: String
    let eventName: String?
    let eventKind: InstructorReviewEventKind
    let chillScore: Int
    let gradingScore: Int
    let reviewText: String
    let submittedAt: Date
    let status: ReviewStatus
}

struct InstructorReviewSeedOverride: Codable, Hashable, Identifiable {
    let id: String
    let instructorName: String?
    let squadronID: String?
    let eventName: String?
    let eventKind: InstructorReviewEventKind?
    let chillScore: Int?
    let gradingScore: Int?
    let reviewText: String?
    let status: ReviewStatus?
}

private struct InstructorReviewSeedBaseFile: Codable {
    let sourceWorkbook: String?
    let generatedAt: Date?
    let reviews: [InstructorReviewSeedItem]
}

private struct InstructorReviewSeedOverrideFile: Codable {
    let overrides: [InstructorReviewSeedOverride]
}

enum InstructorReviewSeedData {
    static let currentSeedVersion = 3
    static let baseFileName = "InstructorReviewSeedBase"
    static let overridesFileName = "InstructorReviewSeedOverrides"

    static let legacyInstructorNames: Set<String> = [
        "Lt. James Holloway",
        "Capt. Maria Torres",
        "Maj. Eric Sutton",
        "Lt. Sarah Bennett",
        "Cmdr. Alex Mercer"
    ]

    static let squadrons: [Squadron] = [
        Squadron(id: "tw-4", displayName: "TW-4"),
        Squadron(id: "tw-5", displayName: "TW-5"),
        Squadron(id: "vt-27", displayName: "VT-27"),
        Squadron(id: "vt-28", displayName: "VT-28"),
        Squadron(id: "vt-2", displayName: "VT-2"),
        Squadron(id: "vt-3", displayName: "VT-3"),
        Squadron(id: "vt-6", displayName: "VT-6")
    ]

    static let events: [InstructorReviewEvent] = [
        InstructorReviewEvent(id: "c3101", displayName: "C3101", kind: .sim),
        InstructorReviewEvent(id: "c3202", displayName: "C3202", kind: .sim),
        InstructorReviewEvent(id: "c3203", displayName: "C3203", kind: .sim),
        InstructorReviewEvent(id: "c3401", displayName: "C3401", kind: .sim),
        InstructorReviewEvent(id: "c4200", displayName: "C4200", kind: .sim),
        InstructorReviewEvent(id: "c4201", displayName: "C4201", kind: .sim),
        InstructorReviewEvent(id: "c4202", displayName: "C4202", kind: .sim),
        InstructorReviewEvent(id: "c4203", displayName: "C4203", kind: .sim),
        InstructorReviewEvent(id: "c4204", displayName: "C4204", kind: .sim),
        InstructorReviewEvent(id: "c4301", displayName: "C4301", kind: .sim),
        InstructorReviewEvent(id: "c4600", displayName: "C4600", kind: .sim),
        InstructorReviewEvent(id: "contacts", displayName: "Contacts", kind: .flight),
        InstructorReviewEvent(id: "day-nav", displayName: "Day Nav", kind: .flight),
        InstructorReviewEvent(id: "fam", displayName: "FAM", kind: .flight),
        InstructorReviewEvent(id: "form-checkride", displayName: "Form Checkride", kind: .flight),
        InstructorReviewEvent(id: "i2103", displayName: "I2103", kind: .sim),
        InstructorReviewEvent(id: "i3100", displayName: "I3100", kind: .sim),
        InstructorReviewEvent(id: "i3101", displayName: "I3101", kind: .sim),
        InstructorReviewEvent(id: "i3102", displayName: "I3102", kind: .sim),
        InstructorReviewEvent(id: "i3202", displayName: "I3202", kind: .sim),
        InstructorReviewEvent(id: "i3203", displayName: "I3203", kind: .sim),
        InstructorReviewEvent(id: "i3205", displayName: "I3205", kind: .sim),
        InstructorReviewEvent(id: "i3206", displayName: "I3206", kind: .sim),
        InstructorReviewEvent(id: "i4101", displayName: "I4101", kind: .flight),
        InstructorReviewEvent(id: "i4102", displayName: "I4102", kind: .flight),
        InstructorReviewEvent(id: "i4103-04", displayName: "I4103/04", kind: .flight),
        InstructorReviewEvent(id: "i4104", displayName: "I4104", kind: .flight),
        InstructorReviewEvent(id: "i4201-4202", displayName: "I4201/4202", kind: .flight),
        InstructorReviewEvent(id: "i4301-4302", displayName: "I4301/4302", kind: .flight),
        InstructorReviewEvent(id: "i4303-4304", displayName: "I4303/4304", kind: .flight),
        InstructorReviewEvent(id: "i4490", displayName: "I4490", kind: .flight),
        InstructorReviewEvent(id: "instrument-flight", displayName: "Instrument Flight", kind: .flight),
        InstructorReviewEvent(id: "on-wing", displayName: "On-wing", kind: .flight),
        InstructorReviewEvent(id: "pel-sim", displayName: "PEL Sim", kind: .sim)
    ]

    static let reviews: [InstructorReviewSeedItem] = {
        loadEditableReviews(
            baseURL: defaultBaseURL(),
            overridesURL: defaultOverridesURL()
        )
    }()

    static func squadron(for id: String) -> Squadron {
        squadrons.first(where: { $0.id == id }) ?? Squadron(id: id, displayName: id.uppercased())
    }

    static func event(for name: String, kind: InstructorReviewEventKind) -> InstructorReviewEvent {
        if let event = events.first(where: { $0.displayName.caseInsensitiveCompare(name) == .orderedSame && $0.kind == kind }) {
            return event
        }

        return InstructorReviewEvent(
            id: makeEventID(from: name, kind: kind),
            displayName: name,
            kind: kind
        )
    }

    static func loadEditableReviews(baseURL: URL?, overridesURL: URL?) -> [InstructorReviewSeedItem] {
        let decoder = seedDecoder()

        let baseReviews = loadBaseReviews(from: baseURL, decoder: decoder)
        guard !baseReviews.isEmpty else { return [] }

        let overrides = loadOverrides(from: overridesURL, decoder: decoder)
        guard !overrides.isEmpty else { return baseReviews }

        let overrideLookup = Dictionary(uniqueKeysWithValues: overrides.map { ($0.id, $0) })
        return baseReviews.map { review in
            guard let override = overrideLookup[review.id] else { return review }
            return review.applying(override)
        }
    }

    static func legacyEvent(forLegacyID id: String) -> InstructorReviewEvent {
        switch id {
        case "fam-2102":
            return InstructorReviewEvent(id: id, displayName: "FAM2102", kind: .flight)
        case "fam-3101":
            return InstructorReviewEvent(id: id, displayName: "FAM3101", kind: .flight)
        case "fam-4203":
            return InstructorReviewEvent(id: id, displayName: "FAM4203", kind: .flight)
        case "i-2102":
            return InstructorReviewEvent(id: id, displayName: "I2102", kind: .sim)
        case "i-2203":
            return InstructorReviewEvent(id: id, displayName: "I2203", kind: .sim)
        case "i-4201":
            return InstructorReviewEvent(id: id, displayName: "I4201", kind: .sim)
        case "out-fam-01":
            return InstructorReviewEvent(id: id, displayName: "Out-and-In FAM", kind: .flight)
        case "sim-ep-04":
            return InstructorReviewEvent(id: id, displayName: "EP Sim 04", kind: .sim)
        default:
            return InstructorReviewEvent(id: id, displayName: id.uppercased(), kind: .flight)
        }
    }

    private static func loadBaseReviews(from url: URL?, decoder: JSONDecoder) -> [InstructorReviewSeedItem] {
        guard
            let url,
            let data = try? Data(contentsOf: url),
            let file = try? decoder.decode(InstructorReviewSeedBaseFile.self, from: data)
        else {
            return []
        }

        return file.reviews
    }

    private static func loadOverrides(from url: URL?, decoder: JSONDecoder) -> [InstructorReviewSeedOverride] {
        guard
            let url,
            let data = try? Data(contentsOf: url),
            let file = try? decoder.decode(InstructorReviewSeedOverrideFile.self, from: data)
        else {
            return []
        }

        return file.overrides
    }

    private static func defaultBaseURL() -> URL? {
        resourceURL(fileName: baseFileName)
    }

    private static func defaultOverridesURL() -> URL? {
        resourceURL(fileName: overridesFileName)
    }

    private static func resourceURL(fileName: String) -> URL? {
        let contentRepository = ContentRepository(bundle: .main)
        if let url = contentRepository.fileURL(for: "AppContent/\(fileName).json") {
            return url
        }

        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            return url
        }

        let sourceRoot = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fallback = sourceRoot
            .appending(path: "AppContent")
            .appending(path: "\(fileName).json")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }

    private static func makeEventID(from name: String, kind: InstructorReviewEventKind) -> String {
        let slug = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "\(kind.rawValue)-\(slug)"
    }

    private static func seedDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension InstructorReviewSeedItem {
    func applying(_ override: InstructorReviewSeedOverride) -> InstructorReviewSeedItem {
        InstructorReviewSeedItem(
            id: id,
            instructorName: override.instructorName ?? instructorName,
            squadronID: override.squadronID ?? squadronID,
            eventName: override.eventName ?? eventName,
            eventKind: override.eventKind ?? eventKind,
            chillScore: override.chillScore ?? chillScore,
            gradingScore: override.gradingScore ?? gradingScore,
            reviewText: override.reviewText ?? reviewText,
            submittedAt: submittedAt,
            status: override.status ?? status
        )
    }
}
