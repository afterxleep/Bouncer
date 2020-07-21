//
//  UserSettingsDefaults.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class UserSettingsDefaults: UserSettingsProtocol {
    
    var hasLaunchedApp: Bool {
        didSet { UserDefaults.standard.set(hasLaunchedApp, forKey: APP_STORAGE_KEYS.HAS_LAUNCHED_APP.rawValue) }
    }
    
    var numberOfLaunches: Int {
        didSet { UserDefaults.standard.set(numberOfLaunches, forKey: APP_STORAGE_KEYS.NUMBER_OF_LAUNCHES.rawValue) }
    }
    
    var lastVersionPromptedForReview: String {
        didSet { UserDefaults.standard.set(lastVersionPromptedForReview, forKey: APP_STORAGE_KEYS.LAST_VERSION_PROMPTED_FOR_REVIEW.rawValue) }
    }
    
    init() {
        self.hasLaunchedApp = UserDefaults.standard.bool(forKey: APP_STORAGE_KEYS.HAS_LAUNCHED_APP.rawValue)
        self.numberOfLaunches = UserDefaults.standard.integer(forKey: APP_STORAGE_KEYS.NUMBER_OF_LAUNCHES.rawValue)
        self.lastVersionPromptedForReview = UserDefaults.standard.string(forKey: APP_STORAGE_KEYS.LAST_VERSION_PROMPTED_FOR_REVIEW.rawValue) ?? ""
    }
}
