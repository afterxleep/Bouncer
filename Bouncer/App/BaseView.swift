//
//  BaseView.swift
//  Bouncer
//

import SwiftUI

struct BaseView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.analytics) private var analytics

    /// Held back briefly so the screen underneath is on screen first; a sheet
    /// already covering the first frame feels like an error, not a question.
    @State private var privacyPromptReady = false

    private var needsPrivacyChoice: Binding<Bool> {
        Binding(
            get: { privacyPromptReady && store.state.settings.analyticsConsent == .unknown },
            // Only answering dismisses it, which flips the state above.
            set: { _ in }
        )
    }

    var body: some View {
        Group {
            if store.state.settings.hasLaunchedApp {
                FilterListContainerView().environmentObject(store)
            } else {
                OnboardingContainerView().environmentObject(store)
            }
        }
        .animation(.smooth, value: store.state.settings.hasLaunchedApp)
        .tint(Brand.tint)
        .task {
            do {
                try await Task.sleep(for: .milliseconds(600))
                privacyPromptReady = true
            } catch {}
        }
        .sheet(isPresented: needsPrivacyChoice) {
            AnalyticsConsentView(onChoice: recordPrivacyChoice)
                .interactiveDismissDisabled()
        }
    }

    private func recordPrivacyChoice(_ choice: AnalyticsConsent) {
        store.dispatch(.settings(action: .setAnalyticsConsent(choice)))
        analytics.track(.privacyChoiceMade(choice, source: .privacySheet))
    }
}

struct BaseView_Previews: PreviewProvider {
    static var previews: some View {
        BaseView()
    }
}
