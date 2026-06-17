import Foundation

struct VideoLibraryFile: Codable {
    var videos: [VideoRecord]
}

struct VideoRecord: Codable {
    var id: String
    var title: String
    var remotePath: String
    var libraryCategory: String
    var phaseIDs: [String]
    var eventCodes: [String]
    var primaryEventCodes: [String]
    var byteSize: Int64?
    var durationSeconds: Double?
    var summary: String
    var tags: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case remotePath
        case libraryCategory
        case phaseIDs
        case eventCodes
        case primaryEventCodes
        case byteSize
        case durationSeconds
        case summary
        case tags
    }

    init(
        id: String,
        title: String,
        remotePath: String,
        libraryCategory: String,
        phaseIDs: [String],
        eventCodes: [String],
        primaryEventCodes: [String],
        byteSize: Int64?,
        durationSeconds: Double?,
        summary: String,
        tags: [String]
    ) {
        self.id = id
        self.title = title
        self.remotePath = remotePath
        self.libraryCategory = libraryCategory
        self.phaseIDs = phaseIDs
        self.eventCodes = eventCodes
        self.primaryEventCodes = primaryEventCodes
        self.byteSize = byteSize
        self.durationSeconds = durationSeconds
        self.summary = summary
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        remotePath = try container.decode(String.self, forKey: .remotePath)
        libraryCategory = try container.decodeIfPresent(String.self, forKey: .libraryCategory) ?? "other"
        phaseIDs = try container.decodeIfPresent([String].self, forKey: .phaseIDs) ?? []
        eventCodes = try container.decodeIfPresent([String].self, forKey: .eventCodes) ?? []
        primaryEventCodes = try container.decodeIfPresent([String].self, forKey: .primaryEventCodes) ?? []
        byteSize = try container.decodeIfPresent(Int64.self, forKey: .byteSize)
        durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let videosDirectory = rootURL.appendingPathComponent("Videos", isDirectory: true)
let libraryURL = rootURL.appendingPathComponent("Primary Gouge/AppContent/VideoLibrary.json")

let existingLibrary: VideoLibraryFile
if let data = try? Data(contentsOf: libraryURL),
   let decoded = try? JSONDecoder().decode(VideoLibraryFile.self, from: data) {
    existingLibrary = decoded
} else {
    existingLibrary = VideoLibraryFile(videos: [])
}

let existingByRemotePath = Dictionary(uniqueKeysWithValues: existingLibrary.videos.map { ($0.remotePath, $0) })
let discovered = discoverMP4s(under: videosDirectory)

let syncedVideos = discovered.map { fileURL -> VideoRecord in
    let remotePath = canonicalRemotePath(for: fileURL, rootURL: rootURL)
    let existing = existingByRemotePath[remotePath]
    let phaseID = inferredPhaseID(for: remotePath)
    let title = existing?.title.nonEmpty ?? inferredTitle(from: fileURL)
    let tags = uniqueStrings(existing?.tags ?? inferredTags(from: fileURL, phaseID: phaseID))
    let byteSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
    let inferredCategory = inferredLibraryCategory(from: fileURL, tags: tags)
    let existingCategory = existing?.libraryCategory.nonEmpty
    let libraryCategory = existingCategory.flatMap { $0 == "other" ? nil : $0 } ?? inferredCategory

    return VideoRecord(
        id: existing?.id ?? sanitizedID(remotePath),
        title: title,
        remotePath: remotePath,
        libraryCategory: libraryCategory,
        phaseIDs: uniqueStrings(existing?.phaseIDs.nonEmptyArray ?? [phaseID].compactMap { $0 }),
        eventCodes: existing?.eventCodes ?? [],
        primaryEventCodes: existing?.primaryEventCodes ?? [],
        byteSize: byteSize,
        durationSeconds: existing?.durationSeconds,
        summary: existing?.summary.nonEmpty ?? "Review video for \(title).",
        tags: tags
    )
}

let output = VideoLibraryFile(videos: syncedVideos.sorted {
    if $0.phaseIDs.first == $1.phaseIDs.first {
        return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
    return ($0.phaseIDs.first ?? "") < ($1.phaseIDs.first ?? "")
})

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(output)
try data.write(to: libraryURL)
print("Wrote \(output.videos.count) videos to \(libraryURL.path)")

func discoverMP4s(under directory: URL) -> [URL] {
    guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]) else {
        return []
    }

    var results: [URL] = []
    while let item = enumerator.nextObject() as? URL {
        guard item.pathExtension.localizedCaseInsensitiveCompare("mp4") == .orderedSame else { continue }
        results.append(item)
    }
    return results.sorted { $0.path < $1.path }
}

func canonicalRemotePath(for fileURL: URL, rootURL: URL) -> String {
    fileURL.path
        .replacingOccurrences(of: rootURL.path + "/", with: "")
        .split(separator: "/")
        .joined(separator: "/")
}

func inferredPhaseID(for remotePath: String) -> String? {
    let components = remotePath.split(separator: "/").map(String.init)
    guard components.count >= 2 else { return nil }

    switch components[1].lowercased() {
    case "contacts":
        return "contacts"
    case "instruments":
        return "instruments"
    case "vnav":
        return "vnav"
    case "formation":
        return "formation"
    case "capstone":
        return "capstone"
    default:
        return nil
    }
}

func inferredTitle(from fileURL: URL) -> String {
    var stem = fileURL.deletingPathExtension().lastPathComponent
    stem = stem.replacingOccurrences(of: #"_[0-9]+$"#, with: "", options: .regularExpression)
    stem = stem.replacingOccurrences(of: #"(^|_)t6b($|_)"#, with: "$1T-6B$2", options: [.regularExpression, .caseInsensitive])
    stem = stem.replacingOccurrences(of: #"(^|_)bi($|_)"#, with: "$1BI$2", options: [.regularExpression, .caseInsensitive])
    stem = stem.replacingOccurrences(of: #"(^|_)gca($|_)"#, with: "$1GCA$2", options: [.regularExpression, .caseInsensitive])
    stem = stem.replacingOccurrences(of: #"(^|_)loe($|_)"#, with: "$1LOE$2", options: [.regularExpression, .caseInsensitive])
    stem = stem.replacingOccurrences(of: "_", with: " ")
    stem = stem.replacingOccurrences(of: "-", with: " ")

    return stem
        .split(whereSeparator: \.isWhitespace)
        .map { word in
            let text = String(word)
            if text.contains("-") || text.uppercased() == text {
                return text
            }
            return text.prefix(1).uppercased() + text.dropFirst().lowercased()
        }
        .joined(separator: " ")
}

func inferredTags(from fileURL: URL, phaseID: String?) -> [String] {
    var tags = phaseID.map { [$0] } ?? []
    let stem = fileURL.deletingPathExtension().lastPathComponent
    let tokens = stem
        .replacingOccurrences(of: #"_[0-9]+$"#, with: "", options: .regularExpression)
        .lowercased()
        .split { !$0.isLetter && !$0.isNumber }
        .map(String.init)
        .filter { !$0.isEmpty }
    tags.append(contentsOf: tokens)
    return uniqueStrings(tags)
}

func inferredLibraryCategory(from fileURL: URL, tags: [String]) -> String {
    let filename = fileURL.deletingPathExtension().lastPathComponent.lowercased()
    let haystack = Set(tags.map { $0.lowercased() } + filename.split { !$0.isLetter && !$0.isNumber }.map(String.init))

    if filename.contains("hot_start") || filename.contains("hung_start") || filename.contains("no_start") || filename.contains("abnormal_start") {
        return "groundEmergencies"
    }

    if filename.contains("engine") || filename.contains("flameout") || filename.contains("fuel_starvation") || filename.contains("loss_of_useful_power") || filename.contains("uncommanded_prop") {
        return "flightEmergencies"
    }

    if filename.contains("normal_start") || filename.contains("start_scan") || filename.contains("hand_signals") {
        return "startSequence"
    }

    if haystack.contains("instruments") || haystack.contains("bi") || haystack.contains("gca") || haystack.contains("scan") || haystack.contains("timed") || haystack.contains("transitions") {
        return "instruments"
    }

    if filename.contains("landing") || filename.contains("takeoff") || filename.contains("pattern") || filename.contains("propeller_sleeve") || filename.contains("crosswind") {
        return "landingPattern"
    }

    if filename.contains("poweronstalls") || filename.contains("poweroffstalls") || filename.contains("turns_and_pitch") {
        return "contactManeuvers"
    }

    if filename.contains("loop") || filename.contains("aileronroll") || filename.contains("barrelroll") || filename.contains("cuban8") || filename.contains("cloverleaf") || filename.contains("immelmann") || filename.contains("splits") || filename.contains("wingover") {
        return "aerobatics"
    }

    return "other"
}

func sanitizedID(_ value: String) -> String {
    var stem = value
        .replacingOccurrences(of: "Videos/", with: "")
        .replacingOccurrences(of: ".mp4", with: "")
        .lowercased()

    stem = stem.replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
    stem = stem.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return "video-\(stem)"
}

func uniqueStrings(_ values: [String]) -> [String] {
    var seen = Set<String>()
    var result: [String] = []

    for value in values {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { continue }
        result.append(trimmed)
    }

    return result
}

extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}

extension Array where Element == String {
    var nonEmptyArray: [String]? {
        isEmpty ? nil : self
    }
}
