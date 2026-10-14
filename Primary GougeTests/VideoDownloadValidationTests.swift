import Foundation
import Testing
@testable import Primary_Gouge

@MainActor
struct VideoDownloadValidationTests {
    @Test func failedEmptyAndNonVideoDownloadsNeverReplaceCachedVideo() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [InvalidVideoProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let downloader = URLSessionVideoDownloader(session: session)
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appending(path: "video.mp4")
        let existing = Data("existing cached video".utf8)
        try existing.write(to: destination)
        for path in ["error", "empty", "html"] {
            do {
                try await downloader.download(from: URL(string: "https://download.test/\(path)")!, to: destination) { _ in }
                Issue.record("Invalid \(path) response was cached as a video")
            } catch {
                #expect(try Data(contentsOf: destination) == existing)
                #expect(!FileManager.default.fileExists(atPath: destination.path + ".download"))
            }
        }
    }
}

private final class InvalidVideoProtocol: URLProtocol, @unchecked Sendable {
    nonisolated override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "download.test" }
    nonisolated override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    nonisolated override func startLoading() {
        let url = request.url!
        let data = url.lastPathComponent == "empty" ? Data() : Data("<html>Not a video</html>".utf8)
        let response = HTTPURLResponse(url: url, statusCode: url.lastPathComponent == "error" ? 503 : 200,
            httpVersion: "HTTP/1.1", headerFields: ["Content-Type":"video/mp4", "Content-Length":String(data.count)])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    nonisolated override func stopLoading() {}
}
