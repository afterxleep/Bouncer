//
//  AppState.swift
//  Bouncer
//

import Foundation
import Combine

// MARK: App State
struct AppState {
    var filters: FilterState
}

// MARK: Filter State
struct FilterState {
    var filters: [Filter] = []
    
}



