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

        case.updateStateFromSettings(let hasLaunchedApp,
                                     let numberOfLaunches,
                                     let lastVersionPromptedForReview):

            state.hasLaunchedApp = hasLaunchedApp
            state.numberOfLaunches = numberOfLaunches
            state.lastVersionPromptedForReview = lastVersionPromptedForReview

        case .setHasLaunchedApp:
            state.hasLaunchedApp = true

        case .setNumberOfLaunches(number: let number):
            state.numberOfLaunches = number

        case .setLastVersionPromptedForReview(version: let version):
            state.lastVersionPromptedForReview = version


    }
}
