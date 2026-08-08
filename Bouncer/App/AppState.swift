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
    var filterError: FilterError? = nil
}

struct SettingsState {
    var hasLaunchedApp: Bool = false
    var numberOfLaunches: Int = 0
    var lastVersionPromptedForReview: String = ""
    var databaseVersion: Int = 0
}

extension SettingsState {

    /// Seeded straight from disk rather than waiting for `fetchSettings`.
    ///
    /// That action resolves through a middleware publisher delivered on the
    /// main queue, so the first render always saw the defaults — and a returning
    /// user got a frame of onboarding before the real value arrived.
    init(store: AppSettingsStore) {
        self.hasLaunchedApp = store.hasLaunchedApp
        self.numberOfLaunches = store.numberOfLaunches
        self.lastVersionPromptedForReview = store.lastVersionPromptedForReview
        self.databaseVersion = store.databaseVersion
    }
}
