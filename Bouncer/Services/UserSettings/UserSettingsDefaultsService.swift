//
//  UserSettingsService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import Combine

final class UserSettingsDefaults: ObservableObject {
    
    private enum keys: String {
        case hasLaunchedApp
    }
    
    @Published var hasLaunchedApp: Bool {
        didSet { UserDefaults.standard.set(hasLaunchedApp, forKey: keys.hasLaunchedApp.rawValue) }
    }
    
    init() {
        self.hasLaunchedApp = UserDefaults.standard.bool(forKey: keys.hasLaunchedApp.rawValue)
    }
}
