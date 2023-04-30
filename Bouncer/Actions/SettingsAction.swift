//
//  SettingsAction.swift
//  Bouncer
//
//  Created by Daniel Bernal on 8/12/20.
//

import SwiftUI

enum SettingsAction {

    case fetchSettings
    case setHasLaunchedApp(status: Bool)
    case setNumberOfLaunches(number: Int)
    case setLastVersionPromptedForReview(version: String)
    case setDatabaseVersion(version: Int)
}
