//
//  AppSettingsStore.swift
//  Bouncers
//

import Foundation

enum AppSettingsKeys: String {
    case hasLaunchedApp
    case numberOfLaunches
    case lastVersionPromptedForReview
}

protocol AppSettingsStore {
    var userDefaults: UserDefaults { get set }
    var hasLaunchedApp: Bool { get set }
    var numberOfLaunches: Int { get set }
    var lastVersionPromptedForReview: String { get set }
}
