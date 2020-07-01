//
//  UserSettingsService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class UserSettings {
    
    var hasLaunchedApp: Bool {
        didSet { UserDefaults.standard.set(hasLaunchedApp, forKey: APP_STORAGE_KEYS.HAS_LAUNCHED_APP.rawValue) }
    }
    
    init() {
        self.hasLaunchedApp = UserDefaults.standard.bool(forKey: APP_STORAGE_KEYS.HAS_LAUNCHED_APP.rawValue)
    }
}
