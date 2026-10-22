import AuthenticationServices
import CryptoKit
import Security
import SwiftUI
import UIKit

struct AccountSignInView: View {
    @EnvironmentObject private var accountStore: AccountStore

    @State private var route: AccountAuthRoute = .welcome
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var verificationCode = ""
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var pendingVerificationEmail: String?
    @State private var pendingResetEmail: String?
    @State private var appleNonce: String?
    @State private var localErrorMessage: String?
    @FocusState private var focusedField: AccountAuthField?

    var body: some View {
        NavigationStack {
            ZStack {
                AuthArtworkBackground()

                switch route {
                case .welcome:
                    welcomeScreen
                        .transition(.opacity)
                case .emailSignIn:
                    emailSignInScreen
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                case .emailCreate:
                    emailCreateScreen
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                case .emailVerify:
                    emailVerifyScreen
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                case .passwordResetRequest:
                    passwordResetRequestScreen
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                case .passwordResetConfirm:
                    passwordResetConfirmScreen
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.28), value: route)
            .toolbar(.hidden, for: .navigationBar)
        }
        .foregroundStyle(StudyDesign.ink).tint(StudyDesign.blue)
        .accessibilityIdentifier("account-sign-in-screen")
        .task {
            #if DEBUG
            if AppLaunchEnvironment.usesPasswordResetConfirmUITest {
                pendingResetEmail = "test@example.com"
                route = .passwordResetConfirm
            }
            #endif
        }
    }

    private var welcomeScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Prepare for\nwhat’s next.").selectedText(32, line: 36.8, weight: .bold, tracking: -1)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 29)
                OnboardingProductArt().padding(.top, 23)
                Text("Find your event, know your instructor, and reinforce what you learn.")
                    .selectedText(14, line: 22.4).foregroundStyle(StudyDesign.secondary)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 17).padding(.bottom, 22)
                VStack(spacing: 10) {
                    authErrorText
                    appleButton
                    Button { move(to: .emailCreate) } label: {
                        AuthButtonLabel(title: "Sign Up with Email", systemImage: "", style: .secondary)
                    }.buttonStyle(.plain)
                    AuthInlineSwitch(prefix: "Already have an account?", actionTitle: "Sign In") { move(to: .emailSignIn) }
                    AuthLegalLinks().padding(.top, 5)
                }.padding(.top, 42)
            }.padding(.horizontal, 24).padding(.bottom, 30)
        }.accessibilityLabel("Primary Gouge")
    }

    private var emailSignInScreen: some View {
        AuthFormScreen(
            title: "Sign In",
            subtitle: "Use the email account you already created.",
            backAction: { move(to: .welcome) }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AccountTextField(
                    title: "Email",
                    placeholder: "name@example.com",
                    text: $email,
                    textContentType: .username,
                    keyboardType: .emailAddress
                )
                .focused($focusedField, equals: .email)

                VStack(alignment: .trailing, spacing: 8) {
                    AccountTextField(
                        title: "Password",
                        placeholder: "Password",
                        text: $password,
                        textContentType: .password,
                        keyboardType: .default,
                        isSecure: true
                    )
                    .focused($focusedField, equals: .password)

                    Button("Forgot Password?") {
                        pendingResetEmail = email.nilIfEmpty
                        move(to: .passwordResetRequest)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(StudyDesign.blue)
                }

                authErrorText
                Spacer(minLength: 18)
                Button {
                    signIn()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Signing In..." : "Sign In", systemImage: "person.crop.circle.badge.checkmark", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || email.nilIfEmpty == nil || password.isEmpty)
                .opacity(accountStore.isWorking || email.nilIfEmpty == nil || password.isEmpty ? 0.62 : 1)

                AuthInlineSwitch(prefix: "Don't have an account?", actionTitle: "Create Account") {
                    move(to: .emailCreate)
                    focusedField = .name
                }
            }
        }
    }

    private var emailCreateScreen: some View {
        AuthFormScreen(
            title: "Create your\naccount.",
            subtitle: "Keep your preparation connected.",
            backAction: { move(to: .emailSignIn) }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AccountTextField(
                    title: "Name",
                    placeholder: "Optional",
                    text: $displayName,
                    textContentType: .name,
                    keyboardType: .default
                )
                .focused($focusedField, equals: .name)

                AccountTextField(
                    title: "Email",
                    placeholder: "name@example.com",
                    text: $email,
                    textContentType: .emailAddress,
                    keyboardType: .emailAddress
                )
                .focused($focusedField, equals: .email)

                AccountTextField(
                    title: "Password",
                    placeholder: "At least 10 characters",
                    text: $password,
                    textContentType: .newPassword,
                    keyboardType: .default,
                    isSecure: true,
                    minimumCharacterCount: AccountAuthValidation.minimumPasswordCharacters,
                    characterCountIdentifier: "password-create-character-guidance"
                )
                .focused($focusedField, equals: .password)

                authErrorText
                Spacer(minLength: 18)
                Button {
                    createAccount()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Creating..." : "Create Account", systemImage: "person.badge.plus.fill", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || email.nilIfEmpty == nil || password.count < AccountAuthValidation.minimumPasswordCharacters)
                .opacity(accountStore.isWorking || email.nilIfEmpty == nil || password.count < AccountAuthValidation.minimumPasswordCharacters ? 0.62 : 1)

                AuthLegalLinks().padding(.top, 8)
                AuthInlineSwitch(prefix: "Already have an account?", actionTitle: "Sign In") {
                    move(to: .emailSignIn)
                    focusedField = .email
                }
            }
        }
    }

    private var emailVerifyScreen: some View {
        AuthFormScreen(
            title: "Check Your Email",
            subtitle: "Enter the 6-digit code sent to \(pendingVerificationEmail ?? email).",
            backAction: { move(to: .emailCreate) }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AccountTextField(
                    title: "Verification Code",
                    placeholder: "6-digit code",
                    text: $verificationCode,
                    textContentType: .oneTimeCode,
                    keyboardType: .numberPad
                )
                .focused($focusedField, equals: .code)

                authErrorText

                Button {
                    verifyEmail()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Verifying..." : "Verify and Continue", systemImage: "checkmark.seal.fill", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)
                .opacity(accountStore.isWorking || verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 ? 0.62 : 1)

                AuthInlineSwitch(prefix: "Wrong email?", actionTitle: "Edit Account") {
                    move(to: .emailCreate)
                    focusedField = .email
                }
            }
        }
    }

    private var passwordResetRequestScreen: some View {
        AuthFormScreen(
            title: "Reset Password",
            subtitle: "We'll send a 6-digit reset code if the account exists.",
            backAction: { move(to: .emailSignIn) }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AccountTextField(
                    title: "Email",
                    placeholder: "name@example.com",
                    text: $email,
                    textContentType: .emailAddress,
                    keyboardType: .emailAddress
                )
                .focused($focusedField, equals: .email)

                authErrorText

                Button {
                    requestReset()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Sending..." : "Send Reset Code", systemImage: "envelope.fill", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || email.nilIfEmpty == nil)
                .opacity(accountStore.isWorking || email.nilIfEmpty == nil ? 0.62 : 1)
            }
        }
    }

    private var passwordResetConfirmScreen: some View {
        AuthFormScreen(
            title: "Enter Reset Code",
            subtitle: "Use the code sent to \(pendingResetEmail ?? email), then choose a new password.",
            backAction: { move(to: .passwordResetRequest) }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                AccountTextField(
                    title: "Reset Code",
                    placeholder: "6-digit code",
                    text: $resetCode,
                    textContentType: .oneTimeCode,
                    keyboardType: .numberPad
                )
                .focused($focusedField, equals: .code)

                AccountTextField(
                    title: "New Password",
                    placeholder: "At least 10 characters",
                    text: $newPassword,
                    textContentType: .newPassword,
                    keyboardType: .default,
                    isSecure: true,
                    minimumCharacterCount: AccountAuthValidation.minimumPasswordCharacters,
                    characterCountIdentifier: "password-reset-character-guidance"
                )
                .focused($focusedField, equals: .newPassword)

                authErrorText

                Button {
                    confirmReset()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Resetting..." : "Reset and Sign In", systemImage: "key.fill", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || resetCode.isEmpty || newPassword.count < AccountAuthValidation.minimumPasswordCharacters)
                .opacity(accountStore.isWorking || resetCode.isEmpty || newPassword.count < AccountAuthValidation.minimumPasswordCharacters ? 0.62 : 1)
            }
        }
    }

    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            let nonce = AccountAppleNonce.randomNonceString()
            let nonceHash = AccountAppleNonce.sha256(nonce)
            appleNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = nonceHash
        } onCompletion: { result in
            handleAppleCompletion(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 49)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var authErrorText: some View {
        if let message = activeErrorMessage {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(StudyDesign.color(0xAE304B, 0xFF968E))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }

    private var activeErrorMessage: String? {
        localErrorMessage ?? accountStore.errorMessage
    }

    private func move(to route: AccountAuthRoute) {
        localErrorMessage = nil
        self.route = route
    }

    private func signIn() {
        localErrorMessage = nil
        Task { @MainActor in
            do {
                try await accountStore.signInWithEmail(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                password = ""
            } catch AccountStoreError.requestFailed(let statusCode, let message) where statusCode == 403 {
                pendingVerificationEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                verificationCode = ""
                route = .emailVerify
                localErrorMessage = friendlyAuthMessage(statusCode: statusCode, message: message)
            } catch {
                localErrorMessage = friendlyAuthMessage(error)
            }
        }
    }

    private func createAccount() {
        localErrorMessage = nil
        Task { @MainActor in
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                try await accountStore.registerWithEmail(
                    email: trimmedEmail,
                    password: password,
                    displayName: displayName.nilIfEmpty
                )
                pendingVerificationEmail = trimmedEmail
                verificationCode = ""
                guard !accountStore.isSignedIn else {
                    password = ""
                    return
                }
                route = .emailVerify
                focusedField = .code
            } catch {
                localErrorMessage = friendlyAuthMessage(error)
            }
        }
    }

    private func verifyEmail() {
        localErrorMessage = nil
        Task { @MainActor in
            do {
                try await accountStore.verifyEmail(
                    email: pendingVerificationEmail ?? email.trimmingCharacters(in: .whitespacesAndNewlines),
                    code: verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                password = ""
                verificationCode = ""
            } catch {
                localErrorMessage = friendlyAuthMessage(error)
            }
        }
    }

    private func requestReset() {
        localErrorMessage = nil
        Task { @MainActor in
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                try await accountStore.requestPasswordReset(email: trimmedEmail)
                pendingResetEmail = trimmedEmail
                resetCode = ""
                newPassword = ""
                route = .passwordResetConfirm
                focusedField = .code
            } catch {
                localErrorMessage = friendlyAuthMessage(error)
            }
        }
    }

    private func confirmReset() {
        localErrorMessage = nil
        Task { @MainActor in
            do {
                try await accountStore.confirmPasswordReset(
                    email: pendingResetEmail ?? email.trimmingCharacters(in: .whitespacesAndNewlines),
                    code: resetCode.trimmingCharacters(in: .whitespacesAndNewlines),
                    newPassword: newPassword
                )
                resetCode = ""
                newPassword = ""
            } catch {
                localErrorMessage = friendlyAuthMessage(error)
            }
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        localErrorMessage = nil

        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityData = credential.identityToken,
                let identityToken = String(data: identityData, encoding: .utf8)
            else {
                localErrorMessage = AccountStoreError.invalidAppleCredential.localizedDescription
                return
            }

            let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            let name = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents()).nilIfEmpty

            Task { @MainActor in
                do {
                    try await accountStore.signInWithApple(
                        identityToken: identityToken,
                        authorizationCode: authorizationCode,
                        displayName: name,
                        email: credential.email,
                        nonce: appleNonce
                    )
                } catch {
                    localErrorMessage = friendlyAuthMessage(error)
                }
            }
        case .failure(let error):
            localErrorMessage = error.localizedDescription
        }
    }

    private func friendlyAuthMessage(_ error: Error) -> String {
        if let networkError = error as? URLError {
            switch networkError.code {
            case .cannotFindHost, .dnsLookupFailed, .cannotConnectToHost, .timedOut, .networkConnectionLost:
                return "We couldn’t reach the sign-in service. Please try again shortly."
            case .notConnectedToInternet:
                return "You’re offline. Connect to the internet and try again."
            default:
                break
            }
        }
        if case AccountStoreError.requestFailed(let statusCode, let message) = error {
            return friendlyAuthMessage(statusCode: statusCode, message: message)
        }
        return error.localizedDescription
    }

    private func friendlyAuthMessage(statusCode: Int, message: String) -> String {
        if statusCode == 404 && message.localizedCaseInsensitiveContains("not found") {
            return "Account service is not available yet. Try again in a moment."
        }
        return message
    }
}

enum AccountAuthValidation {
    static let minimumPasswordCharacters = 10
}

struct AuthArtworkBackground: View {
    var body: some View { StudyDesign.color(0xFFFFFF, 0x111923).ignoresSafeArea() }
}

struct AuthFormScreen<Content: View>: View {
    let title: String
    let subtitle: String
    let backAction: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Color.clear.frame(width: 35, height: 35).overlay {
                            Button(action: backAction) { Image(systemName: "arrow.left").font(.system(size: 20)).frame(width: 44, height: 44) }
                                .buttonStyle(.plain).accessibilityLabel("Back")
                        }
                        Spacer()
                        Text("Account").selectedText(11).foregroundStyle(StudyDesign.secondary)
                    }.padding(.bottom, 45)
                    Text(title).selectedText(32, line: 36.8, weight: .bold, tracking: -1)
                    Text(subtitle).selectedText(14, line: 22.4).foregroundStyle(StudyDesign.secondary).padding(.top, 14).padding(.bottom, 25)
                    content
                }.frame(minHeight: max(0, geometry.size.height - 37), alignment: .topLeading)
                    .padding(.horizontal, 24).padding(.top, 15).padding(.bottom, 22)
            }.scrollDismissesKeyboard(.interactively).foregroundStyle(StudyDesign.ink)
        }
    }
}

struct AuthButtonLabel: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let systemImage: String
    let style: Style

    var body: some View {
        Text(title).selectedText(15, line: 21, weight: .semibold)
            .foregroundStyle(style == .primary ? .white : StudyDesign.blue)
            .frame(maxWidth: .infinity).padding(14).frame(minHeight: 49)
            .background(style == .primary ? StudyDesign.action : StudyDesign.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay { if style == .secondary { RoundedRectangle(cornerRadius: 24).strokeBorder(StudyDesign.color(0xCAD7E9, 0x445B78), lineWidth: 1) } }
    }
}
struct AuthInlineSwitch: View {
    let prefix: String
    let actionTitle: String
    let action: () -> Void
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 5) { Text(prefix); Button(actionTitle, action: action).foregroundStyle(StudyDesign.blue) }
            VStack(spacing: 5) { Text(prefix); Button(actionTitle, action: action).foregroundStyle(StudyDesign.blue).frame(minHeight: 44) }
        }.selectedText(12).foregroundStyle(StudyDesign.secondary).frame(maxWidth: .infinity).padding(.vertical, 9)
    }
}

private struct AuthLegalLinks: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 5) { Text("By signing up, you agree to the"); links }
            VStack(spacing: 5) { Text("By signing up, you agree to the"); HStack(spacing: 12) { links } }
        }.selectedText(10, line: 16).foregroundStyle(StudyDesign.secondary).frame(maxWidth: .infinity)
    }
    @ViewBuilder private var links: some View {
        NavigationLink("Terms") { MoreArticleView(page: MoreArticleContentLoader.page(.terms), accent: MoreSectionColor.about, iconName: "doc.text") }
        Text("and")
        NavigationLink("Privacy Policy") { MoreArticleView(page: MoreArticleContentLoader.page(.privacy), accent: MoreSectionColor.about, iconName: "lock.shield") }
    }
}

private enum AccountAuthRoute: Hashable {
    case welcome
    case emailSignIn
    case emailCreate
    case emailVerify
    case passwordResetRequest
    case passwordResetConfirm
}

private enum AccountAuthField: Hashable {
    case name
    case email
    case password
    case code
    case newPassword
}

private enum AccountAppleNonce {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else {
                fatalError("Unable to generate secure nonce.")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}
