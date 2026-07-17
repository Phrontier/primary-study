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

    static var usesFreeUITestAccount: Bool {
        isUITesting && arguments.contains("--ui-testing-free-account")
    }

    static var usesSignedOutUITestAccount: Bool {
        isUITesting && arguments.contains("--ui-testing-signed-out")
    }

    static var usesPasswordResetConfirmUITest: Bool {
        isUITesting && arguments.contains("--ui-testing-reset-confirm")
    }
#else
    static let isUITesting = false
    static let usesSignedInUITestAccount = false
    static let usesFreeUITestAccount = false
    static let usesSignedOutUITestAccount = false
    static let usesPasswordResetConfirmUITest = false
#endif
}
