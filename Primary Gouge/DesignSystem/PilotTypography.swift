import SwiftUI
import UIKit

/// Measured roles from the selected root, detail and flashcard studies.
enum PilotTextRole {
    case title, subtitle, section, destination, tool, code, pill, sessionPill, sessionTitle
    case metadata, body, overview, prompt, answer, footer, grade, preview, stat, action, library, readingHeading, state, excerpt
    var size: CGFloat {
        switch self {
        case .title: 30
        case .subtitle: 13
        case .grade, .excerpt: 12
        case .state: 11
        case .action, .library: 14
        case .readingHeading: 17
        case .section: 17
        case .destination: 18
        case .tool, .preview: 16
        case .code, .pill, .metadata: 11
        case .sessionPill, .footer: 10
        case .sessionTitle: 22
        case .body, .overview: 14
        case .prompt: 28
        case .answer: 15
        case .stat: 25
        }
    }
    var line: CGFloat {
        switch self {
        case .title: 35.5
        case .subtitle: 20.8
        case .section: 20
        case .readingHeading: 23.8
        case .action: 20
        case .library: 16.5
        case .destination: 24.3
        case .tool: 21.6
        case .code: 19
        case .pill: 13
        case .sessionPill: 11.5
        case .metadata: 16.5
        case .state: 19
        case .excerpt: 18
        case .sessionTitle: 27.5
        case .body: 23.1
        case .overview: 22.4
        case .prompt: 35
        case .answer: 24.75
        case .footer: 15
        case .grade: 18
        case .preview: 22.4
        case .stat: 29.7
        }
    }
    var weight: Font.Weight {
        switch self {
        case .title, .section, .destination, .tool, .code, .sessionTitle, .prompt, .preview, .stat, .library, .readingHeading: .bold
        case .pill, .sessionPill, .grade, .action, .state: .semibold
        default: .regular
        }
    }
    var tracking: CGFloat {
        switch self {
        case .title: -1
        case .section, .readingHeading: -0.3
        case .tool, .preview: -0.25
        case .code, .pill, .sessionPill: 1.1
        case .sessionTitle: -0.5
        case .prompt: -0.7
        default: 0
        }
    }
    var relative: Font.TextStyle {
        switch self {
        case .title, .stat: .largeTitle
        case .sessionTitle, .prompt: .title2
        case .code, .pill, .sessionPill, .metadata, .footer: .caption
        default: .body
        }
    }
}
extension View {
    func pilotText(_ role: PilotTextRole) -> some View { modifier(DesignMeasuredType(size: role.size, line: role.line, weight: role.weight, tracking: role.tracking, relativeTo: role.relative, minimumLineBox: true)) }
    func pilotNavigation() -> some View {
        toolbar(.hidden, for: .navigationBar).background(PilotPopGestureBridge().frame(width: 0, height: 0))
    }
}

struct PilotPage<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 20)
        }
        .background(StudyDesign.page.ignoresSafeArea()).foregroundStyle(StudyDesign.ink)
    }
}

struct PilotBackHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Color.clear.frame(height: 23).overlay(alignment: .leading) {
            Button { dismiss() } label: {
                HStack(spacing: 9) {
                    Image(systemName: "arrow.left").font(.system(size: 17, weight: .regular))
                        .frame(width: 19).accessibilityHidden(true)
                    Text(title).pilotText(.subtitle)
                }.foregroundStyle(StudyDesign.blue).frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel("Back to \(title)").accessibilityIdentifier("pilot-back")
        }.padding(.bottom, 20)
    }
}

/// Keep interactive back navigation when these screens hide the system bar.
private struct PilotPopGestureBridge: UIViewRepresentable {
    func makeUIView(context: Context) -> Anchor { Anchor() }
    func updateUIView(_ uiView: Anchor, context: Context) { uiView.scheduleInstall() }
    static func dismantleUIView(_ uiView: Anchor, coordinator: ()) { uiView.restoreGestureDelegate() }

    final class Anchor: UIView, UIGestureRecognizerDelegate {
        private weak var previousDelegate: UIGestureRecognizerDelegate?
        private weak var recognizer: UIGestureRecognizer?
        private weak var owner: UINavigationController?
        private weak var contentRecognizer: UIGestureRecognizer?
        private weak var previousContentDelegate: UIGestureRecognizerDelegate?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil { restoreGestureDelegate() } else { scheduleInstall() }
        }
        func scheduleInstall() {
            DispatchQueue.main.async { [weak self] in self?.install() }
        }
        private func install() {
            guard window != nil else { return }
            var responder: UIResponder? = self
            var navigation: UINavigationController?
            while let current = responder {
                if let controller = current as? UIViewController, let candidate = controller.navigationController {
                    navigation = candidate
                    break
                }
                responder = current.next
            }
            if navigation == nil {
                let candidates = navigations(in: window?.rootViewController)
                navigation = candidates.filter { $0.topViewController?.viewIfLoaded?.window != nil }
                    .max { $0.viewControllers.count < $1.viewControllers.count }
            }
            guard let navigation, let gesture = navigation.interactivePopGestureRecognizer else { return }
            owner = navigation
            recognizer = gesture
            if gesture.delegate !== self { previousDelegate = gesture.delegate }
            gesture.delegate = self
            gesture.isEnabled = navigation.viewControllers.count > 1
            if #available(iOS 26.0, *), let content = navigation.interactiveContentPopGestureRecognizer {
                contentRecognizer = content
                if content.delegate !== self { previousContentDelegate = content.delegate }
                content.delegate = self
                content.isEnabled = navigation.viewControllers.count > 1
            }
        }
        private func navigations(in controller: UIViewController?) -> [UINavigationController] {
            guard let controller else { return [] }
            if let presented = controller.presentedViewController { return navigations(in: presented) }
            if let tabs = controller as? UITabBarController { return navigations(in: tabs.selectedViewController) }
            if let navigation = controller as? UINavigationController { return [navigation] }
            return controller.children.flatMap { navigations(in: $0) }
        }
        func restoreGestureDelegate() {
            if recognizer?.delegate === self { recognizer?.delegate = previousDelegate }
            if contentRecognizer?.delegate === self { contentRecognizer?.delegate = previousContentDelegate }
            contentRecognizer = nil
            owner = nil
            recognizer = nil
        }
        override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return (owner?.viewControllers.count ?? 0) > 1 && owner?.transitionCoordinator == nil
        }
    }
}
