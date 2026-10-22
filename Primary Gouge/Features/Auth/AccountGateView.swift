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
                if accountStore.profileComplete && !AppLaunchEnvironment.usesTrainingSetupUITest {
                    content
                } else {
                    AccountOnboardingView()
                }
            }
        }
    }
}

private struct AccountLoadingView: View {
    var title = "Loading Account"

    var body: some View {
        ZStack {
            AppTheme.groupedBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(AppTheme.accent)

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(StudyDesign.ink)
            }
        }
    }
}

struct AccountOnboardingView: View {
    @EnvironmentObject private var accountStore: AccountStore

    @State private var displayName = ""
    @State private var selectedSquadronID = AccountProfile.notSureSquadronID
    @State private var selectedSyllabus = SyllabusTrack.echo
    @State private var didLoad = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack { Image(systemName: "paperplane").foregroundStyle(StudyDesign.blue); Spacer(); Text("Training setup").selectedText(11).foregroundStyle(StudyDesign.secondary) }.frame(minHeight: 44).padding(.bottom, 45)
                    Text("Make it your\nstudy cockpit.").selectedText(32, line: 36.8, weight: .bold, tracking: -1)
                    Text("Choose your training defaults.").selectedText(14, line: 22.4).foregroundStyle(StudyDesign.secondary).padding(.top, 14).padding(.bottom, 25)
                    VStack(alignment: .leading, spacing: 22) {
                        AccountTextField(title: "Display Name", placeholder: "Optional", text: $displayName, textContentType: .name, keyboardType: .default)
                        AccountSquadronPicker(selection: $selectedSquadronID)
                        AccountSyllabusPicker(selection: $selectedSyllabus)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Not sure yet? Start with Echo.").selectedText(13, line: 18.2, weight: .semibold).foregroundStyle(StudyDesign.blue)
                        Text("You can always update it in Profile settings later.").selectedText(12, line: 19.2).foregroundStyle(StudyDesign.secondary)
                    }.padding(.vertical, 14).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(StudyDesign.blueFill, in: RoundedRectangle(cornerRadius: 16)).padding(.vertical, 25)
                    if let errorMessage { Text(errorMessage).foregroundStyle(AppTheme.danger).selectedText(12).padding(.bottom, 12) }
                    Button { saveProfile() } label: { SelectedPrimaryLabel(title: accountStore.isWorking ? "Saving…" : "Continue") }.buttonStyle(.plain).disabled(accountStore.isWorking)
                }.padding(.horizontal, 24).padding(.top, 15).padding(.bottom, 35)
            }.background(StudyDesign.color(0xFFFFFF, 0x111923).ignoresSafeArea()).foregroundStyle(StudyDesign.ink).tint(StudyDesign.blue)
                .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            loadProfileOnce()
        }
        .onChange(of: selectedSquadronID) { _, newValue in
            if newValue == AccountProfile.notSureSquadronID {
                selectedSyllabus = .echo
            }
        }
    }

    private func loadProfileOnce() {
        guard !didLoad else { return }
        didLoad = true
        let profile = accountStore.profile
        displayName = profile?.displayName ?? ""
        selectedSquadronID = AccountProfile.normalizedProfileSquadronID(profile?.squadronID)
        selectedSyllabus = profile?.syllabusID ?? .echo
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
            Text("Squadron")
                .selectedText(12, weight: .semibold)
                .foregroundStyle(StudyDesign.secondary)

            Picker("Squadron", selection: $selection) {
                ForEach(options, id: \.id) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 13)
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
            Text("Syllabus")
                .selectedText(12, weight: .semibold)
                .foregroundStyle(StudyDesign.secondary)

            Picker("Syllabus", selection: $selection) {
                ForEach(SyllabusTrack.allCases) { track in
                    Text(track.title).tag(track)
                }
            }
            .pickerStyle(.menu).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading).background(AccountFieldBackground())
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
    var minimumCharacterCount: Int? = nil
    var characterCountIdentifier: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .selectedText(12, weight: .semibold)
                .foregroundStyle(StudyDesign.secondary)

            Group {
                if isSecure {
                    SecureField(title, text: $text, prompt: Text(placeholder).foregroundStyle(StudyDesign.secondary))
                        .textContentType(textContentType)
                } else {
                    TextField(title, text: $text, prompt: Text(placeholder).foregroundStyle(StudyDesign.secondary))
                        .textContentType(textContentType)
                }
            }
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .selectedText(14, line: 20)
            .foregroundStyle(StudyDesign.ink)
            .padding(.vertical, 13)
            .frame(minHeight: 48)
            .background(AccountFieldBackground())
            .accessibilityIdentifier("account-field-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")

            if let minimumCharacterCount {
                CharacterGuidance(
                    text: text,
                    minimum: minimumCharacterCount,
                    identifier: characterCountIdentifier ?? "\(title.lowercased().replacingOccurrences(of: " ", with: "-"))-character-guidance"
                )
            }
        }
    }
}

struct AccountFieldBackground: View {
    var body: some View {
        Color.clear.overlay(alignment: .bottom) { Rectangle().fill(StudyDesign.color(0xCCD6E4, 0x445B78)).frame(height: 1) }

    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
