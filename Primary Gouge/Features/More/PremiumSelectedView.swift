import SwiftUI
import StoreKit

struct SelectedPremiumScreen: View {
    let lockedFeatureTitle: String?
    @EnvironmentObject private var store: SubscriptionStore
    @EnvironmentObject private var notifications: NotificationService
    @Environment(\.dismiss) private var dismiss
    @State private var showingManage = false
    @State private var showingReminder = false
    @State private var reminderMessage: String?
    private var fixture: Bool {
        #if DEBUG
        AppLaunchEnvironment.isUITesting && ProcessInfo.processInfo.arguments.contains("--premium-fidelity-fixture")
        #else
        false
        #endif
    }
    private var trialDays: Int? { fixture ? 7 : store.product?.freeTrialDays }
    private var hasTrial: Bool { fixture || store.trialDescription != nil }
    private var offer: String { fixture ? "7 days free, then $9.99 per month" : store.offerDescription }
    private var active: Bool { store.hasPremiumAccess }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: 20) {
                    if active {
                        SelectedSurface {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Premium Is Active", systemImage: "checkmark.shield").selectedText(18, weight: .bold).accessibilityIdentifier("premium-status")
                                Text(store.entitlement.phase == .gracePeriod ? "Premium remains available during Apple’s billing grace period." : "Your complete study cockpit is ready.").selectedText(14, line: 21).foregroundStyle(StudyDesign.secondary)
                                if let date = store.entitlement.expirationDate, store.entitlement.environment != "AppReview" {
                                    Text("Current access through \(date.formatted(date: .abbreviated, time: .omitted)).").selectedText(12).foregroundStyle(StudyDesign.secondary)
                                }
                            }
                        }
                    } else {
                        if store.entitlement.phase != .notSubscribed { statusNotice }
                        timeline
                    }
                    VStack(spacing: 9) {
                        if let lockedFeatureTitle { Text("Unlock \(lockedFeatureTitle)").selectedText(15, weight: .bold) }
                        Text(active ? "Premium Monthly" : offer).selectedText(16, line: 23.2, weight: .bold)
                        Text(active ? "Manage your subscription with Apple." : "Billed monthly through your Apple Account.").selectedText(12, line: 18).foregroundStyle(StudyDesign.secondary)
                        Label("Secured by Apple", systemImage: "checkmark.shield").selectedText(11).foregroundStyle(StudyDesign.secondary)
                            .padding(.horizontal, 11).padding(.vertical, 7).overlay(Capsule().strokeBorder(StudyDesign.cardLine)).padding(.vertical, 6)
                        Button {
                            if fixture { showingReminder = true; return }
                            if active { showingManage = true }
                            else if hasTrial { showingReminder = true }
                            else { Task { await store.purchase() } }
                        } label: { SelectedPrimaryLabel(title: buttonTitle, cornerRadius: 15, fontSize: 16, weight: .bold) }.buttonStyle(.plain)
                            .disabled(store.isWorking || store.purchaseIsPending || (!active && !fixture && !store.isPurchaseLaunchEnabled))
                        if store.isWorking { ProgressView("Checking with the App Store…").selectedText(12) }
                        if let error = store.errorMessage { Text(error).selectedText(12).foregroundStyle(AppTheme.danger) }
                        if let reminderMessage { Text(reminderMessage).selectedText(12).foregroundStyle(StudyDesign.secondary) }
                        if store.purchaseIsPending { Text("Your purchase is awaiting Apple’s approval.").selectedText(12) }
                        NavigationLink { planDetails } label: { Text("See plan details").selectedText(13, weight: .semibold).frame(minHeight: 44) }.buttonStyle(.plain)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 17) { footerLinks }
                            VStack(spacing: 5) { footerLinks }
                        }.selectedText(10).foregroundStyle(StudyDesign.secondary)
                    }.multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.bottom, 15)
                }.padding(.horizontal, 18).padding(.top, -64).padding(.bottom, 30)
            }
        }.background(SelectedHeroPageBackground()).foregroundStyle(StudyDesign.ink).pilotNavigation()
            .toolbar(.hidden, for: .tabBar).toolbarColorScheme(.dark, for: .navigationBar)
            .manageSubscriptionsSheet(isPresented: $showingManage)
            .sheet(isPresented: $showingReminder) { reminderScreen.presentationDragIndicator(.visible) }
            .task { await store.refresh() }
    }
    @ViewBuilder private var statusNotice: some View {
        SelectedSurface {
            VStack(alignment: .leading, spacing: 10) {
                switch store.entitlement.phase {
                case .loading:
                    ProgressView("Checking Premium").selectedText(14)
                case .billingRetry:
                    Text("Payment Needs Attention").selectedText(17, weight: .bold)
                    Text("Update your payment method with Apple to renew Premium.").selectedText(13).foregroundStyle(StudyDesign.secondary)
                    Button("Manage Subscription") { showingManage = true }.frame(minHeight: 44)
                case .expired:
                    Text("Premium Has Expired").selectedText(17, weight: .bold)
                    Text("Your previous subscription is no longer active.").selectedText(13).foregroundStyle(StudyDesign.secondary)
                case .error:
                    Text("Premium status unavailable").selectedText(17, weight: .bold)
                    Text(store.entitlement.message ?? "Your status could not be verified. Try restoring purchases when connected.").selectedText(13).foregroundStyle(StudyDesign.secondary)
                default: EmptyView()
                }
            }
        }
    }
    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(active ? "Your membership" : "Let’s get started").selectedText(15, weight: .semibold).foregroundStyle(.white.opacity(0.8))
                Spacer()
                Color.clear.frame(width: 36, height: 36).overlay { Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 20)).frame(width: 44, height: 44).background(.white.opacity(0.14), in: Circle()) }.buttonStyle(.plain).accessibilityLabel("Close Premium offer") }
            }.padding(.bottom, 9)
            Text(active ? "Ready for\nwhat’s next." : hasTrial ? "How your free\ntrial works" : "Prepare with\nthe full picture.")
                .selectedText(35, line: 37.8, weight: .bold, tracking: -1.1)
            Text("More confidence for your next event.").selectedText(12, line: 18).foregroundStyle(.white.opacity(0.86)).padding(.top, 15)
        }.padding(.horizontal, 23).padding(.top, 15).padding(.bottom, 106).frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .bottomTrailing) { PremiumAviationArt().opacity(0.75).offset(x: 8, y: -8) }
            .background(LinearGradient(colors: [Color(red: 103/255, green: 148/255, blue: 237/255), StudyDesign.action], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea(edges: .top)).foregroundStyle(.white)
    }
    private var timeline: some View {
        VStack(alignment: .leading, spacing: 25) {
            step("Today", "Unlock the complete event pipeline, study library, and Premium tools.", "lock.open")
            if hasTrial {
                step(trialDays == 7 ? "Day 5" : "Before your trial ends", "Get a notification before your trial ends, with reminders enabled.", "bell")
                step(trialDays.map { "Day \($0)" } ?? "After your trial", "Your monthly subscription starts. Cancel before renewal to avoid payment.", "star")
            } else {
                step("Monthly access", "One monthly plan, billed through your Apple Account.", "calendar")
                step("Your choice", "Manage or cancel your subscription in Apple’s subscription settings.", "star")
            }
        }.padding(.vertical, 23).padding(.horizontal, 19).padding(.bottom, 4)
            .background(alignment: .leading) {
                GeometryReader { g in
                    Capsule().fill(LinearGradient(colors: [StudyDesign.color(0xD9E7FB, 0x324969), StudyDesign.color(0xD3EEE3, 0x335248)], startPoint: .top, endPoint: .bottom))
                        .overlay(alignment: .top) { Capsule().fill(StudyDesign.action).frame(height: max(0, g.size.height - 21)) }
                }.frame(width: 30).padding(.leading, 19).padding(.top, 23).padding(.bottom, 32)
            }
            .background(StudyDesign.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(StudyDesign.cardLine, lineWidth: 1))
    }
    private func step(_ title: String, _ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon).font(.system(size: 19)).foregroundStyle(.white).frame(width: 30, height: 30).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).selectedText(18, line: 21.5, weight: .bold, tracking: -0.3).padding(.top, 1)
                Text(text).selectedText(14, line: 21).foregroundStyle(StudyDesign.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    @ViewBuilder private var footerLinks: some View {
        Button("Restore purchases") { Task { await store.restorePurchases() } }.disabled(store.isWorking).frame(minHeight: 44)
        NavigationLink("Privacy") { MoreArticleView(page: MoreArticleContentLoader.page(.privacy), accent: MoreSectionColor.about, iconName: "lock.shield") }.frame(minHeight: 44)
        NavigationLink("Terms") { MoreArticleView(page: MoreArticleContentLoader.page(.terms), accent: MoreSectionColor.about, iconName: "doc.text") }.frame(minHeight: 44)
    }
    private var planDetails: some View {
        PilotPage {
            PilotBackHeader(title: "Premium")
            StudyHeading(title: "Premium Monthly", subtitle: store.offerDescription).padding(.bottom, 25)
            Text("Payment is charged to your Apple Account. Renews automatically unless cancelled at least 24 hours before the current period ends.").selectedText(14, line: 22.4).padding(.bottom, 20)
            Text("Home, instructor gouge, emergency-reference flashcards, Contacts ground school, FAM2101, and FAM2102 remain free.").selectedText(14, line: 22.4)
        }.pilotNavigation()
    }
    private var buttonTitle: String {
        if active { return "Manage Subscription" }
        if store.purchaseIsPending { return "Awaiting Approval" }
        if store.isWorking { return "Working…" }
        return store.isPurchaseLaunchEnabled || fixture ? "Continue" : "Premium Unavailable"
    }
    private var reminderScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "bell").font(.system(size: 32)).foregroundStyle(StudyDesign.blue).padding(20).background(StudyDesign.blueFill, in: RoundedRectangle(cornerRadius: 20))
                Text("A reminder before\nyour trial ends.").pilotText(.title)
                Text("Allow notifications for a reminder two days before your trial expires. You can also continue without reminders.").selectedText(14, line: 22.4).foregroundStyle(StudyDesign.secondary)
                Button { if fixture { showingReminder = false; return }; Task { let allowed = await notifications.requestAuthorization(); await purchase(remind: allowed) } } label: { SelectedPrimaryLabel(title: "Allow reminders and continue") }.buttonStyle(.plain)
                Button("Continue without reminders") { if fixture { showingReminder = false; return }; Task { await purchase(remind: false) } }.frame(maxWidth: .infinity, minHeight: 44)
            }.padding(24)
        }.background(StudyDesign.page).foregroundStyle(StudyDesign.ink)
    }
    @MainActor private func purchase(remind: Bool) async {
        showingReminder = false
        guard await store.purchase() == .purchased, remind, let end = store.entitlement.expirationDate else { return }
        let scheduled = await notifications.scheduleTrialEndingReminder(endsAt: end)
        reminderMessage = scheduled ? "Your trial-ending reminder is scheduled." : "A trial reminder couldn’t be scheduled. Manage renewal with Apple."
    }
}
