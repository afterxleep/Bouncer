//
//  Protocols.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/22/20.
//

// MARK: - StoreObserverDelegate

protocol StoreObserverDelegate: AnyObject {
    /// Tells the delegate that the restore operation was successful.
    func storeObserverRestoreDidSucceed()
    
    /// Provides the delegate with messages.
    func storeObserverDidReceiveMessage(_ message: String)
}

// MARK: - StoreManagerDelegate\

protocol StoreManagerDelegate: AnyObject {
    /// Provides the delegate with the App Store's response.
    func storeManagerDidReceiveResponse(_ response: [ProductSection])
    
    /// Provides the delegate with the error encountered during the product request.
    func storeManagerDidReceiveMessage(_ message: String)
}
