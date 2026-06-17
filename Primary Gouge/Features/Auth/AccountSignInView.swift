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
            .ignoresSafeArea()
            .animation(.snappy(duration: 0.28), value: route)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var welcomeScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 120)

            VStack(alignment: .leading, spacing: 14) {
                Text("Primary Gouge")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.78)
                    .lineLimit(1)

                Text("Your study cockpit for Primary.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 42)

            VStack(spacing: 12) {
                appleButton

                Button {
                    move(to: .emailCreate)
                    focusedField = .email
                } label: {
                    AuthButtonLabel(title: "Sign up with Email", systemImage: "envelope.fill", style: .secondary)
                }
                .buttonStyle(.plain)

                AuthInlineSwitch(prefix: "Already have an account?", actionTitle: "Sign in") {
                    move(to: .emailSignIn)
                    focusedField = .email
                }
                .padding(.top, -2)

                VStack(spacing: 5) {
                    Text("By signing up, you agree to the Privacy and Terms.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))

                    HStack(spacing: 10) {
                        NavigationLink("Privacy") {
                            MoreArticleView(page: MoreArticleContentLoader.page(.privacy), accent: MoreSectionColor.about, iconName: "lock.shield.fill")
                        }
                        Text("•")
                            .foregroundStyle(.white.opacity(0.48))
                        NavigationLink("Terms") {
                            MoreArticleView(page: MoreArticleContentLoader.page(.terms), accent: MoreSectionColor.about, iconName: "doc.text.fill")
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var emailSignInScreen: some View {
        AuthFormScreen(
            title: "Sign in",
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

                    Button("Forgot password?") {
                        pendingResetEmail = email.nilIfEmpty
                        move(to: .passwordResetRequest)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                }

                authErrorText

                Button {
                    signIn()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Signing In..." : "Sign In", systemImage: "person.crop.circle.badge.checkmark", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || email.nilIfEmpty == nil || password.isEmpty)
                .opacity(accountStore.isWorking || email.nilIfEmpty == nil || password.isEmpty ? 0.62 : 1)

                AuthInlineSwitch(prefix: "Don't have an account?", actionTitle: "Create account") {
                    move(to: .emailCreate)
                    focusedField = .name
                }
            }
        }
    }

    private var emailCreateScreen: some View {
        AuthFormScreen(
            title: "Create account",
            subtitle: "Apple is still the fastest path. Email works too.",
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
                    isSecure: true
                )
                .focused($focusedField, equals: .password)

                authErrorText

                Button {
                    createAccount()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Creating..." : "Create Account", systemImage: "person.badge.plus.fill", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || email.nilIfEmpty == nil || password.count < 10)
                .opacity(accountStore.isWorking || email.nilIfEmpty == nil || password.count < 10 ? 0.62 : 1)

                AuthInlineSwitch(prefix: "Already have an account?", actionTitle: "Sign in") {
                    move(to: .emailSignIn)
                    focusedField = .email
                }
            }
        }
    }

    private var emailVerifyScreen: some View {
        AuthFormScreen(
            title: "Check your email",
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

                AuthInlineSwitch(prefix: "Wrong email?", actionTitle: "Edit account") {
                    move(to: .emailCreate)
                    focusedField = .email
                }
            }
        }
    }

    private var passwordResetRequestScreen: some View {
        AuthFormScreen(
            title: "Reset password",
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
            title: "Enter reset code",
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
                    isSecure: true
                )
                .focused($focusedField, equals: .newPassword)

                authErrorText

                Button {
                    confirmReset()
                } label: {
                    AuthButtonLabel(title: accountStore.isWorking ? "Resetting..." : "Reset and Sign In", systemImage: "key.fill", style: .primary)
                }
                .buttonStyle(.plain)
                .disabled(accountStore.isWorking || resetCode.isEmpty || newPassword.count < 10)
                .opacity(accountStore.isWorking || resetCode.isEmpty || newPassword.count < 10 ? 0.62 : 1)
            }
        }
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signUp) { request in
            let nonce = AccountAppleNonce.randomNonceString()
            let nonceHash = AccountAppleNonce.sha256(nonce)
            appleNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = nonceHash
        } onCompletion: { result in
            handleAppleCompletion(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var authErrorText: some View {
        if let message = activeErrorMessage {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.74, blue: 0.68))
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

struct AuthArtworkBackground: View {
    var body: some View {
        GeometryReader { proxy in
            authArtworkImage
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.10),
                            Color.black.opacity(0.28),
                            Color.black.opacity(0.78)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(red: 0.02, green: 0.17, blue: 0.17).opacity(0.44)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .ignoresSafeArea()
        }
    }

    private var authArtworkImage: Image {
        guard
            let url = Bundle.main.url(forResource: "AuthWelcome", withExtension: "png"),
            let image = UIImage(contentsOfFile: url.path)
        else {
            return Image(uiImage: Self.fallbackImage)
        }

        return Image(uiImage: image)
    }

    private static var fallbackImage: UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 64))
        return renderer.image { context in
            UIColor(red: 0.02, green: 0.13, blue: 0.15, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 64))
        }
    }
}

struct AuthFormScreen<Content: View>: View {
    let title: String
    let subtitle: String
    let backAction: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Button {
                    backAction()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.14), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.20), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)

                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 78)
            .padding(.bottom, 44)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))

            Text(title)
                .font(.system(.body, design: .rounded, weight: .bold))
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(stroke, lineWidth: 1)
        )
    }

    private var foreground: Color {
        switch style {
        case .primary:
            return Color(red: 0.03, green: 0.16, blue: 0.16)
        case .secondary:
            return .white
        }
    }

    private var background: Color {
        switch style {
        case .primary:
            return Color(red: 0.55, green: 0.78, blue: 0.70)
        case .secondary:
            return Color.white.opacity(0.13)
        }
    }

    private var stroke: Color {
        switch style {
        case .primary:
            return Color.white.opacity(0.28)
        case .secondary:
            return Color.white.opacity(0.38)
        }
    }
}

struct AuthInlineSwitch: View {
    let prefix: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Spacer(minLength: 0)
            Text(prefix)
                .foregroundStyle(.white.opacity(0.70))
            Button(actionTitle, action: action)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .font(.footnote)
        .padding(.top, 4)
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
