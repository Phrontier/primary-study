import SwiftUI
import AVKit

struct VideoDetailView: View {
    let video: VideoAsset
    @EnvironmentObject private var appModel: StudyAppModel
    @EnvironmentObject private var videoDownloadStore: VideoDownloadStore

    var body: some View {
        AppScrollScreen(bottomPadding: 40) {
            playerOrDownloadState

            HeroCard(
                eyebrow: "Video",
                title: video.title,
                subtitle: video.summary
            ) {
                if let byteSize = video.byteSize {
                    Text(ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .detailNavigationChrome(title: "Video")
        .task {
            appModel.recordVideoOpened(video)
        }
    }

    @ViewBuilder
    private var playerOrDownloadState: some View {
        switch videoDownloadStore.status(for: video) {
        case let .available(url):
            VideoPlayer(player: AVPlayer(url: url))
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )

        case let .downloading(progress):
            downloadStateCard(
                    title: "Downloading Video",
                message: "\(Int(progress * 100))% complete"
            ) {
                ProgressView(value: progress)
                    .tint(AppTheme.domainColor(.videos))
            }

        case let .failed(message):
            downloadStateCard(
                    title: "Video Unavailable",
                message: message
            ) {
                downloadButton(title: "Try Again")
            }

        case .notDownloaded:
            downloadStateCard(
                    title: "Available to Download",
                message: downloadMessage
            ) {
                downloadButton(title: "Download")
            }
        }
    }

    private var downloadMessage: String {
        if let byteSize = video.byteSize {
            return "\(ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)) download for offline playback."
        }
        return "Download once for offline playback."
    }

    private func downloadStateCard<Content: View>(
        title: String,
        message: String,
        @ViewBuilder action: () -> Content
    ) -> some View {
        SectionContainer {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "play.rectangle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.domainColor(.videos))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                action()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func downloadButton(title: String) -> some View {
        Button {
            Task {
                await videoDownloadStore.download(video)
            }
        } label: {
            Label(title, systemImage: "arrow.down.circle.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.domainColor(.videos))
        .disabled(videoDownloadStore.remoteURL(for: video) == nil)
    }
}
