import Foundation

enum AppLaunchEnvironment {
    #if DEBUG
    private static let arguments = Set(ProcessInfo.processInfo.arguments)

    static var isUITesting: Bool {
        arguments.contains("--ui-testing")
    }

    static var usesSignedInUITestAccount: Bool {
        isUITesting && arguments.contains("--ui-testing-signed-in")
    }

    static var usesModeratorUITestAccount: Bool {
        isUITesting && arguments.contains("--ui-testing-moderator")
    }

    static var usesFreeUITestAccount: Bool {
        isUITesting && arguments.contains("--ui-testing-free-account")
    }

    static var usesSignedOutUITestAccount: Bool {
        isUITesting && arguments.contains("--ui-testing-signed-out")
    }

    static var usesTrainingSetupUITest: Bool { isUITesting && arguments.contains("--ui-testing-training-setup") }

    static var usesPasswordResetConfirmUITest: Bool {
        isUITesting && arguments.contains("--ui-testing-reset-confirm")
    }
#else
    static let isUITesting = false
    static let usesSignedInUITestAccount = false
    static let usesModeratorUITestAccount = false
    static let usesFreeUITestAccount = false
    static let usesSignedOutUITestAccount = false
    static let usesPasswordResetConfirmUITest = false
    static let usesTrainingSetupUITest = false
#endif
}
