//
//  BouncerApp.swift
//  Bouncer
//

import SwiftUI
import StoreKit

@main
struct BouncerApp: App {
    
    let store: AppStore
    let analytics: AnalyticsTracking

    init() {
        let appSettings = AppSettingsDefaults(userDefaults: UserDefaults.standard)
        PostHogConfiguration.configure(optedIn: appSettings.analyticsConsent.isGranted)

        let launchNumber = appSettings.numberOfLaunches + 1
        let launch = AnalyticsLaunchContext(
            cohort: InstallCohortStore(userDefaults: .standard)
                .resolve(numberOfLaunches: appSettings.numberOfLaunches,
                         hasLaunchedApp: appSettings.hasLaunchedApp,
                         now: Date()),
            launchNumber: launchNumber,
            onboardingCompleted: appSettings.hasLaunchedApp,
            appVersion: Bundle.main.displayVersion
        )
        // Re-read on every call so a change in Help applies to the very next event.
        let analytics = ConsentGatedAnalyticsTracker(
            wrapped: PostHogAnalyticsTracker(),
            isGranted: { AppSettingsDefaults(userDefaults: .standard).analyticsConsent.isGranted }
        )
        self.analytics = analytics

        // Settings are read synchronously here so the first frame already knows
        // whether setup is finished; going through `fetchSettings` alone meant
        // onboarding flashed on every launch for a user who had completed it.
        store = AppStore(
            initialState: .init(settings: SettingsState(store: appSettings),
                                filters: FilterState()),
            reducer: appReducer,
            middlewares: [
                settingsMiddleware(appSettings: appSettings),
                // After settings, so a new answer is persisted before it is read.
                analyticsMiddleware(tracker: analytics, launch: launch, now: Date.init),
                filterMiddleware(filterStore: FilterStoreFile(),
                                 analyticsService: DefaultAnalyticsService()),
                reviewMiddleware(reviewService: ReviewServiceStoreKit(appSettings: appSettings)),
            ]
        )

        // Fetch existing filters
        store.dispatch(.filter(action: .fetch))

        // Increase launch number
        store.dispatch(.settings(action: .setNumberOfLaunches(number: launchNumber)))
        store.dispatch(.settings(action: .appLaunched))
    }
    
    var body: some Scene {
        WindowGroup {
            BaseView()
                .environmentObject(store)
                .environment(\.analytics, analytics)
        }
    }
}
