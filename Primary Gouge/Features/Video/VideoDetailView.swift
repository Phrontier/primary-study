import SwiftUI
import AVKit

struct VideoDetailView: View {
    let video: VideoAsset
    @EnvironmentObject private var appModel: StudyAppModel

    var body: some View {
        AppScrollScreen(bottomPadding: 40) {
            VideoPlayer(player: AVPlayer(url: video.url))
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )

            HeroCard(
                eyebrow: "Video",
                title: video.title,
                subtitle: video.summary
            )
        }
        .scrollActivatedNavigationChrome(title: "Video")
        .task {
            appModel.recordVideoOpened(video)
        }
    }
}
