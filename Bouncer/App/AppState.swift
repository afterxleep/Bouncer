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
    var inApp: InAppState
}

// MARK: Filter State
struct FilterState {
    var filters: [Filter] = []
}

struct SettingsState {
    var maximumFreeFilters: Int = 2
    var hasPurchasedUpgrade: Bool = false
    var hasLaunchedApp: Bool = false
    var numberOfLaunches: Int = 0
    var lastVersionPromptedForReview: String = ""
}

struct InAppState {
    var availableProducts: [Product] = []
    var purchasedProducts: [Product] = []
    var transactionInProgress: Bool = false
}
