//
//  AppReducer.swift
//  Bouncer
//

import Foundation
import Combine

func settingsReducer(state: inout SettingsState, action: SettingsAction) -> Void {

    switch action {

        case .fetchSettings:
            break

        case .setHasLaunchedApp(let status):
            state.hasLaunchedApp = status

        case .setNumberOfLaunches(let number):
            state.numberOfLaunches = number

        case .setLastVersionPromptedForReview(let version):
            state.lastVersionPromptedForReview = version


    }
}
