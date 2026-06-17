import SwiftUI
import UIKit

struct AccountGateView<Content: View>: View {
    @EnvironmentObject private var accountStore: AccountStore
    @ViewBuilder let content: Content

    var body: some View {
        Group {
            switch accountStore.phase {
            case .loading:
                AccountLoadingView()
            case .signedOut:
                AccountSignInView()
            case .signedIn:
                if accountStore.profileComplete {
                    content
                } else {
                    AccountOnboardingView()
                }
            }
        }
    }
}

private struct AccountLoadingView: View {
    var body: some View {
        ZStack {
            AppTheme.groupedBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(AppTheme.accent)

                Text("Loading Account")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
}

struct AccountOnboardingView: View {
    @EnvironmentObject private var accountStore: AccountStore

    @State private var displayName = ""
    @State private var selectedSquadronID = AccountProfile.notSureSquadronID
    @State private var selectedSyllabus = SyllabusTrack.delta
    @State private var didLoad = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AuthArtworkBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Set up your profile")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(accountStore.profile?.email ?? "Choose the training defaults Primary Gouge should use.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.76))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 74)

                        VStack(alignment: .leading, spacing: 14) {
                            AccountTextField(
                                title: "Display Name",
                                placeholder: "Optional",
                                text: $displayName,
                                textContentType: .name,
                                keyboardType: .default
                            )

                            AccountSquadronPicker(selection: $selectedSquadronID)
                            AccountSyllabusPicker(selection: $selectedSyllabus)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color(red: 1.0, green: 0.74, blue: 0.68))
                            }

                            Button {
                                saveProfile()
                            } label: {
                                AuthButtonLabel(
                                    title: accountStore.isWorking ? "Saving..." : "Continue",
                                    systemImage: "checkmark.circle.fill",
                                    style: .primary
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(accountStore.isWorking)
                            .opacity(accountStore.isWorking ? 0.62 : 1)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
                }
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            loadProfileOnce()
        }
    }

    private func loadProfileOnce() {
        guard !didLoad else { return }
        didLoad = true
        let profile = accountStore.profile
        displayName = profile?.displayName ?? ""
        selectedSquadronID = AccountProfile.normalizedProfileSquadronID(profile?.squadronID)
        selectedSyllabus = profile?.syllabusID ?? .delta
    }

    private func saveProfile() {
        errorMessage = nil
        Task { @MainActor in
            do {
                try await accountStore.updateProfile(
                    displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    squadronID: AccountProfile.normalizedProfileSquadronID(selectedSquadronID),
                    syllabusID: selectedSyllabus
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct AccountSquadronPicker: View {
    @Binding var selection: String

    private var options: [(id: String, title: String)] {
        [(AccountProfile.notSureSquadronID, "Not Sure Yet")] +
        InstructorReviewSeedData.squadrons.profileSelectableSorted().map { ($0.id, $0.displayName) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SQUADRON")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)

            Picker("Squadron", selection: $selection) {
                ForEach(options, id: \.id) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AccountFieldBackground())
            .onAppear {
                selection = AccountProfile.normalizedProfileSquadronID(selection)
            }
            .onChange(of: selection) { _, newValue in
                selection = AccountProfile.normalizedProfileSquadronID(newValue)
            }
        }
    }
}

struct AccountSyllabusPicker: View {
    @Binding var selection: SyllabusTrack

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYLLABUS")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)

            Picker("Syllabus", selection: $selection) {
                ForEach(SyllabusTrack.allCases) { track in
                    Text(track.title).tag(track)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct AccountTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(textContentType)
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(textContentType)
                }
            }
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(minHeight: 54)
            .background(AccountFieldBackground())
        }
    }
}

struct AccountFieldBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(AppTheme.elevatedSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
            )
    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
