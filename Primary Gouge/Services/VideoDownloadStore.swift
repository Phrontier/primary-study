import Foundation
import Combine

enum VideoDownloadStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case available(URL)
    case failed(String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }
}

protocol VideoDownloader {
    func download(from remoteURL: URL, to destinationURL: URL, progress: @escaping (Double) async -> Void) async throws
}

struct URLSessionVideoDownloader: VideoDownloader {
    func download(from remoteURL: URL, to destinationURL: URL, progress: @escaping (Double) async -> Void) async throws {
        let temporaryURL = destinationURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(destinationURL.lastPathComponent).download", isDirectory: false)

        if FileManager.default.fileExists(atPath: temporaryURL.path) {
            try FileManager.default.removeItem(at: temporaryURL)
        }

        FileManager.default.createFile(atPath: temporaryURL.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: temporaryURL)

        do {
            let (bytes, response) = try await URLSession.shared.bytes(from: remoteURL)
            let expectedLength = response.expectedContentLength
            var receivedLength: Int64 = 0
            var buffer = Data()
            buffer.reserveCapacity(64 * 1024)

            for try await byte in bytes {
                buffer.append(byte)
                receivedLength += 1

                if buffer.count >= 64 * 1024 {
                    try fileHandle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }

                if expectedLength > 0, receivedLength % (256 * 1024) == 0 {
                    await progress(min(1.0, Double(receivedLength) / Double(expectedLength)))
                }
            }

            if !buffer.isEmpty {
                try fileHandle.write(contentsOf: buffer)
            }

            try fileHandle.close()

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
            await progress(1.0)
        } catch {
            try? fileHandle.close()
            try? FileManager.default.removeItem(at: temporaryURL)
            throw error
        }
    }
}

struct VideoDeliveryConfiguration {
    static let baseURLInfoKey = "VideoContentBaseURL"
    private static let defaultBaseURLString = "https://pub-7ac4ea52c09148848751015b25fdacfd.r2.dev"

    static var baseURL: URL? {
        if let value = Bundle.main.object(forInfoDictionaryKey: baseURLInfoKey) as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return URL(string: trimmed)
            }
        }

        return URL(string: defaultBaseURLString)
    }
}

@MainActor
final class VideoDownloadStore: ObservableObject {
    @Published private var statuses: [String: VideoDownloadStatus] = [:]

    private let cacheDirectory: URL
    private let downloader: VideoDownloader
    private let baseURLProvider: () -> URL?
    private var activeDownloadIDs = Set<String>()

    convenience init() {
        self.init(
            cacheDirectory: Self.defaultCacheDirectory(),
            downloader: URLSessionVideoDownloader(),
            baseURLProvider: { VideoDeliveryConfiguration.baseURL }
        )
    }

    init(
        cacheDirectory: URL,
        downloader: VideoDownloader,
        baseURLProvider: @escaping () -> URL?
    ) {
        self.cacheDirectory = cacheDirectory
        self.downloader = downloader
        self.baseURLProvider = baseURLProvider
        try? prepareCacheDirectory()
    }

    static func defaultCacheDirectory() -> URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return applicationSupport.appendingPathComponent("VideoCache", isDirectory: true)
    }

    func status(for video: VideoAsset) -> VideoDownloadStatus {
        let localURL = cachedFileURL(for: video)
        if FileManager.default.fileExists(atPath: localURL.path) {
            return .available(localURL)
        }
        return statuses[video.id] ?? .notDownloaded
    }

    func cachedFileURL(for video: VideoAsset) -> URL {
        let pathExtension = video.remotePathURLPathExtension ?? "mp4"
        return cacheDirectory.appendingPathComponent("\(sanitizedFileStem(video.id)).\(pathExtension)")
    }

    func remoteURL(for video: VideoAsset) -> URL? {
        if let absoluteURL = URL(string: video.remotePath), absoluteURL.scheme != nil {
            return absoluteURL
        }

        guard var url = baseURLProvider() else { return nil }
        for component in video.remotePath.split(separator: "/") {
            url.appendPathComponent(String(component))
        }
        return url
    }

    @discardableResult
    func download(_ video: VideoAsset) async -> URL? {
        let localURL = cachedFileURL(for: video)
        if FileManager.default.fileExists(atPath: localURL.path) {
            statuses[video.id] = .available(localURL)
            return localURL
        }

        guard !activeDownloadIDs.contains(video.id) else { return nil }
        guard let remoteURL = remoteURL(for: video) else {
            statuses[video.id] = .failed("Video host is not configured.")
            return nil
        }

        activeDownloadIDs.insert(video.id)
        statuses[video.id] = .downloading(progress: 0)

        do {
            try prepareCacheDirectory()
            try await downloader.download(from: remoteURL, to: localURL) { [weak self] progress in
                await MainActor.run {
                    self?.statuses[video.id] = .downloading(progress: progress)
                }
            }
            activeDownloadIDs.remove(video.id)
            statuses[video.id] = .available(localURL)
            return localURL
        } catch {
            activeDownloadIDs.remove(video.id)
            statuses[video.id] = .failed(error.localizedDescription)
            return nil
        }
    }

    func downloadAll(_ videos: [VideoAsset]) async {
        for video in videos {
            _ = await download(video)
        }
    }

    private func prepareCacheDirectory() throws {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = cacheDirectory
        try? mutableURL.setResourceValues(values)
    }

    private func sanitizedFileStem(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let stem = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return stem.isEmpty ? UUID().uuidString : stem
    }
}

private extension VideoAsset {
    var remotePathURLPathExtension: String? {
        if let url = URL(string: remotePath), !url.pathExtension.isEmpty {
            return url.pathExtension
        }

        let pathExtension = URL(fileURLWithPath: remotePath).pathExtension
        return pathExtension.isEmpty ? nil : pathExtension
    }
}
