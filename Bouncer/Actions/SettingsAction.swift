//
//  SettingsAction.swift
//  Bouncer
//
//  Created by Daniel Bernal on 8/12/20.
//

import SwiftUI

enum SettingsAction {

    case fetchSettings
    case updateStateFromSettings(hasLaunchedApp: Bool,
                                 NumberOfLaunches: Int,
                                 lastVersionPromptedForReview: String)
    case setHasLaunchedApp
    case setNumberOfLaunches(number: Int)
    case setLastVersionPromptedForReview(version: String)
}
