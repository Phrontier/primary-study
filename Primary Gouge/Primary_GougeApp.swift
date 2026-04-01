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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .environmentObject(quizStore)
                .environmentObject(reviewStore)
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
