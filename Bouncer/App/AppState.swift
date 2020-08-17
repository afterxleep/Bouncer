//
//  AppState.swift
//  Bouncer
//

import Foundation
import Combine

// MARK: App State
struct AppState {
    var settings: SettingsState
    var filters: FilterState
}

// MARK: Filter State
struct FilterState {
    var filters: [Filter] = []
}

struct SettingsState {
    var hasPurchasedUpgrade: Bool = false
    var hasLaunchedApp: Bool = false
    var numberOfLaunches: Int = 0
    var lastVersionPromptedForReview: String = ""
}
