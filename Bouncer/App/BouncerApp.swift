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
                            filters: FilterState()
                        ),
                      reducer: appReducer,
                      middlewares: []
    )

    init() {
        
        // Add the storeObserver to the queue
        //SKPaymentQueue.default().add(storeObserver)
        
        // Initial State
        store.dispatch(.filter(action: .load))
        
    }
    
    var body: some Scene {
        WindowGroup {
            BaseView().environmentObject(store)
        }
    }
}
