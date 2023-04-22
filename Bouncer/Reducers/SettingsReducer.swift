//
//  AppReducer.swift
//  Bouncer
//

import Foundation

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

        case .setDatabaseVersion(let version):
            state.databaseVersion = version

    }
}
