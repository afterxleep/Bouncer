//
//  AppSettings.swift
//  Bouncer
//

import Foundation

struct AppSettingsDefaults: AppSettingsStore {
    var userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var hasLaunchedApp: Bool {
        get { return value(for: AppSettingsKeys.hasLaunchedApp.rawValue) ?? false }
        set { updateDefaults(for: AppSettingsKeys.hasLaunchedApp.rawValue, value: newValue) }
    }

    var numberOfLaunches: Int {
        get { return value(for: AppSettingsKeys.numberOfLaunches.rawValue) ?? 0 }
        set { updateDefaults(for: AppSettingsKeys.numberOfLaunches.rawValue, value: newValue) }
    }

    var lastVersionPromptedForReview: String {
        get { return value(for: AppSettingsKeys.lastVersionPromptedForReview.rawValue) ?? "" }
        set { updateDefaults(for: AppSettingsKeys.lastVersionPromptedForReview.rawValue, value: newValue) }
    }
    
}

// MARK: Private methods

extension AppSettingsDefaults {

    private func updateDefaults(for key: String, value: Any) {
        userDefaults.set(value, forKey: key)
    }

    private func value<T>(for key: String) -> T? {
        return userDefaults.value(forKey: key) as? T
    }

}
