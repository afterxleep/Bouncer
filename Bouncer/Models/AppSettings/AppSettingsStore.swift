//
//  AppSettingsInterface.swift
//  FreshlyPressed
//
//  Created by Daniel Bernal on 8/8/20.
//  Copyright © 2020 Automattic. All rights reserved.
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
