import SwiftUI
import QuickLook

struct DocumentPreviewScreen: View {
    let document: SourceDocument
    private let repository = ContentRepository()

    var body: some View {
        Group {
            if let url = repository.fileURL(for: document.relativePath) {
                DocumentQuickLookView(url: url)
                    .detailNavigationChrome(title: document.title)
            } else {
                AppScrollScreen {
                    EmptyStateCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Document unavailable",
                        message: "The source file could not be found in the app bundle. Re-run the import pipeline or verify the bundle resource path."
                    )
                }
            }
        }
    }
}

struct SharedResourceDetailView: View {
    let resource: SharedResource
    private let repository = ContentRepository()
    @EnvironmentObject private var appModel: StudyAppModel

    var body: some View {
        Group {
            if let relativePath = resource.relativePath,
               let url = repository.fileURL(for: relativePath) {
                DocumentQuickLookView(url: url)
                    .detailNavigationChrome(title: resource.title)
                    .task {
                        appModel.recordSharedResourceOpened(resource)
                    }
            } else {
                AppScrollScreen {
                    HeroCard(
                        eyebrow: "Reference",
                        title: resource.title,
                        subtitle: "Reference ready in text form"
                    ) {
                        Text(resource.summary)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .detailNavigationChrome(title: resource.title)
                .task {
                    appModel.recordSharedResourceOpened(resource)
                }
            }
        }
    }
}

struct DocumentQuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
