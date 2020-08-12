//
//  AppSettings.swift
//  Bouncer
//

import Foundation

class AppSettingsDefaults: AppSettingsStore {
    var userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var hasLaunchedApp: Bool {
        get { return self.value(for: AppSettingsKeys.hasLaunchedApp.rawValue) ?? false }
        set { self.updateDefaults(for: AppSettingsKeys.hasLaunchedApp.rawValue, value: newValue) }
    }

    var numberOfLaunches: Int {
        get { return self.value(for: AppSettingsKeys.numberOfLaunches.rawValue) ?? 0 }
        set { self.updateDefaults(for: AppSettingsKeys.numberOfLaunches.rawValue, value: newValue) }
    }

    var lastVersionPromptedForReview: String {
        get { return self.value(for: AppSettingsKeys.lastVersionPromptedForReview.rawValue) ?? "" }
        set { self.updateDefaults(for: AppSettingsKeys.lastVersionPromptedForReview.rawValue, value: newValue) }
    }
    
}

// MARK: Private methods

extension AppSettingsDefaults {

    fileprivate func updateDefaults(for key: String, value: Any) {
        self.userDefaults.set(value, forKey: key)
    }

    fileprivate func value<T>(for key: String) -> T? {
        return self.userDefaults.value(forKey: key) as? T
    }

}
