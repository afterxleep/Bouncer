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
    
    init() {
        // Add the storeObserver to the queue        
        SKPaymentQueue.default().add(storeObserver)
    }
    
    var body: some Scene {
        WindowGroup {
            BaseView()
        }
    }
}
