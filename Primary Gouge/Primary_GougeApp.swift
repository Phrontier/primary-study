//
//  Primary_GougeApp.swift
//  Primary Gouge
//
//  Created by Conway Bolt on 3/27/26.
//

import SwiftUI

@main
struct Primary_GougeApp: App {
    @StateObject private var accountStore = AccountStore()
    @StateObject private var appModel = StudyAppModel()
    @StateObject private var quizStore = QuizStore()
    @StateObject private var reviewStore = InstructorReviewStore()
    @StateObject private var communityStore = CommunitySubmissionStore()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var videoDownloadStore = VideoDownloadStore()
    @State private var didConfigureProtectedStores = false

    init() {
        AppTheme.configureSystemChrome()
    }

    var body: some Scene {
        WindowGroup {
            AccountGateView {
                RootView()
            }
                .environmentObject(accountStore)
                .environmentObject(appModel)
                .environmentObject(quizStore)
                .environmentObject(reviewStore)
                .environmentObject(communityStore)
                .environmentObject(notificationService)
                .environmentObject(videoDownloadStore)
                .preferredColorScheme(AppTheme.preferredColorScheme)
                .task {
                    await bootstrapIfNeeded()
                }
                .onChange(of: accountStore.phase) { _, phase in
                    guard phase == .signedIn else { return }
                    Task {
                        await configureProtectedStoresIfNeeded()
                    }
                }
                .onChange(of: accountStore.profile?.permissions ?? []) { _, _ in
                    reviewStore.setModeratorPermission(
                        accountStore.hasPermission(.instructorGougeModerator)
                    )
                }
                .onChange(of: accountStore.profile?.selectedSyllabus ?? .notSure) { _, syllabus in
                    appModel.selectSyllabus(syllabus)
                }
        }
    }

    @MainActor
    private func bootstrapIfNeeded() async {
        await accountStore.configure()
        await configureProtectedStoresIfNeeded()
    }

    @MainActor
    private func configureProtectedStoresIfNeeded() async {
        guard accountStore.isSignedIn else { return }

        appModel.selectSyllabus(accountStore.profile?.selectedSyllabus ?? .notSure)

        reviewStore.setModeratorPermission(
            accountStore.hasPermission(.instructorGougeModerator)
        )

        accountStore.localDataResetHandler = {
            appModel.resetLocalAccountData()
            quizStore.resetLocalData()
            reviewStore.clearAccountScopedData()
            communityStore.clearLocalAccountData()
        }

        guard !didConfigureProtectedStores else { return }
        didConfigureProtectedStores = true

        reviewStore.configure()
        communityStore.configure()
        quizStore.configure()
        appModel.configure(quizStore: quizStore)
        await notificationService.syncDailyStudyReminder(with: appModel.homePreferences)
    }
}
