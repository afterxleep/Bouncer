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
    var importedFilters: [Filter] = []
    var filterImportInProgress: Bool = false
}

struct SettingsState {
    var hasLaunchedApp: Bool = false
    var numberOfLaunches: Int = 0
    var lastVersionPromptedForReview: String = ""
    var databaseVersion: Int = 0
}
