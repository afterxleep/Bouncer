//
//  DataTypes.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/22/20.
//

import Foundation


enum StoreTransactionState {
    case notInitiated
    case processing
    case completed
    case failed
    case cancelled
    case restored
    case restoreFailed
}
