//
//  BouncerApp.swift
//  Bouncer
//

import SwiftUI
import StoreKit

@main
struct BouncerApp: App {
    
    // Store Payments Observer
    let storeObserver = StoreObserver.shared
    
    let store = AppStore(initialState: .init(                            
                        settings: SettingsState(),
                        filters: FilterState()
                        ),
                      reducer: appReducer,
                      middlewares: [
                        settingsMiddleware(appSettings: AppSettingsDefaults(userDefaults: UserDefaults.standard)),
                        filterMiddleware(filterStore: FilterStoreFile())
                      ]
    )

    init() {
        
        // Add the storeObserver to the queue
        SKPaymentQueue.default().add(storeObserver)
        
        // Fetch existing settings
        store.dispatch(.settings(action: .fetchSettings))

        // FetchExisting Filters
        store.dispatch(.filter(action: .fetch))
        
    }
    
    var body: some Scene {
        WindowGroup {
            BaseView().environmentObject(store)
        }
    }
}
