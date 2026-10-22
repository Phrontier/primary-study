import SwiftUI
import Combine

struct InstructorReviewDetailView: View {
    @EnvironmentObject private var reviewStore: InstructorReviewStore
    @EnvironmentObject private var searchChrome: SearchChromeModel
    @StateObject private var viewModel: InstructorReviewDetailViewModel
    @State private var activeReportTarget: InstructorGougeReportTarget?
    @State private var showingReportConfirmation = false

    init(instructor: Instructor) {
        _viewModel = StateObject(wrappedValue: InstructorReviewDetailViewModel(instructor: instructor))
    }

    var body: some View {
        PilotPage {
            PilotBackHeader(title: "Instructors")
            StudyHeading(title: viewModel.instructor.name, subtitle: viewModel.instructor.squadron.displayName + " · " + viewModel.instructor.capabilityBadges.map(\.pluralDisplayName).joined(separator: " · "))
            HStack {
                Text(viewModel.instructor.publishedReviewCountText).selectedText(11).foregroundStyle(StudyDesign.secondary)
                Spacer()
                Button("Report") { activeReportTarget = .instructor(viewModel.instructor) }.selectedText(11).frame(minHeight: 44)
            }.padding(.top, 7).padding(.bottom, 25)
            Text("At a glance").pilotText(.section).padding(.leading, 15)
                .overlay(alignment: .leading) { Rectangle().fill(StudyDesign.blue).frame(width: 3) }.padding(.bottom, 20)
            SelectedInstructorScores(chill: viewModel.instructor.averageChillScore, grading: viewModel.instructor.averageGradingScore).padding(.bottom, 30)
            HStack {
                Text("Reviews").pilotText(.section)
                Spacer()
                Picker("Sort reviews", selection: $viewModel.selectedSort) {
                    ForEach(InstructorReviewSortOption.allCases) { option in Text(option.title).tag(option) }
                }.pickerStyle(.menu).selectedText(11)
            }.padding(.bottom, 12)
            if viewModel.reviews.isEmpty {
                EmptyStateCard(icon: "tray", title: "No Approved Reviews Yet", message: "Approved reviews will appear here automatically.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.reviews) { review in
                        SelectedInstructorReview(review: review) { activeReportTarget = .review(review) }
                    }
                }
            }
        }
        .pilotNavigation()
        .task {
            viewModel.load(using: reviewStore)
        }
        .onReceive(reviewStore.$revision.dropFirst()) { _ in
            viewModel.load(using: reviewStore)
        }
        .onAppear {
            searchChrome.updateScope(.instructors)
        }
        .sheet(item: $activeReportTarget) { target in
            InstructorGougeReportSheet(target: target) {
                showingReportConfirmation = true
            }
        }
        .alert("Report sent", isPresented: $showingReportConfirmation) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Thanks. The report has been sent to moderation for review.")
        }
    }
}
