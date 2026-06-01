//
//  Primary_GougeApp.swift
//  Primary Gouge
//
//  Created by Conway Bolt on 3/27/26.
//

import SwiftUI

@main
struct Primary_GougeApp: App {
    @StateObject private var appModel = StudyAppModel()
    @StateObject private var quizStore = QuizStore()
    @StateObject private var reviewStore = InstructorReviewStore()
    @StateObject private var communityStore = CommunitySubmissionStore()
    @StateObject private var notificationService = NotificationService()
    @State private var didBootstrap = false

    init() {
        AppTheme.configureSystemChrome()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .environmentObject(quizStore)
                .environmentObject(reviewStore)
                .environmentObject(communityStore)
                .environmentObject(notificationService)
                .preferredColorScheme(AppTheme.preferredColorScheme)
                .task {
                    await bootstrapIfNeeded()
                }
        }
    }

    @MainActor
    private func bootstrapIfNeeded() async {
        guard !didBootstrap else { return }
        didBootstrap = true

        reviewStore.configure()
        communityStore.configure()
        quizStore.configure()
        appModel.configure(quizStore: quizStore)
        await notificationService.syncDailyStudyReminder(with: appModel.homePreferences)
    }
}
