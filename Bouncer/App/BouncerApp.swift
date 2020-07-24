//
//  BouncerApp.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/24/20.
//

import SwiftUI
import StoreKit

@main
struct BouncerApp: App {
    
    // Store Payments Observer
    let storeObserver = StoreObserver.shared
    
    let store = AppStore(initialState: .init(),
                         reducer: appReducer,
                         environment: AppEnvironment())
        
    init() {
        
        // Add the storeObserver to the queue
        SKPaymentQueue.default().add(storeObserver)
        
        // Initial State
        store.send(.filter(action: .load))
        
    }
    
    var body: some Scene {
        WindowGroup {
            BaseView().environmentObject(store)
        }
    }
}
