//
//  BouncerApp.swift
//  Bouncer
//

import SwiftUI
import StoreKit

@main
struct BouncerApp: App {
    
    let store: AppStore

    init() {
        let appSettings = AppSettingsDefaults(userDefaults: UserDefaults.standard)

        // Settings are read synchronously here so the first frame already knows
        // whether setup is finished; going through `fetchSettings` alone meant
        // onboarding flashed on every launch for a user who had completed it.
        store = AppStore(
            initialState: .init(settings: SettingsState(store: appSettings),
                                filters: FilterState()),
            reducer: appReducer,
            middlewares: [
                settingsMiddleware(appSettings: appSettings),
                filterMiddleware(filterStore: FilterStoreFile(),
                                 analyticsService: DefaultAnalyticsService()),
                reviewMiddleware(reviewService: ReviewServiceStoreKit(appSettings: appSettings)),
            ]
        )

        // Fetch existing filters
        store.dispatch(.filter(action: .fetch))

        // Increase launch number
        store.dispatch(.settings(action: .setNumberOfLaunches(number: store.state.settings.numberOfLaunches + 1)))
    }
    
    var body: some Scene {
        WindowGroup {
            BaseView().environmentObject(store)
        }
    }
}
