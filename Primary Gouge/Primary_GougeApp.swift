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
                .preferredColorScheme(AppTheme.preferredColorScheme)
                .task {
                    bootstrapIfNeeded()
                }
        }
    }

    @MainActor
    private func bootstrapIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true

        reviewStore.configure()
        quizStore.configure()
        appModel.configure(quizStore: quizStore)
    }
}
