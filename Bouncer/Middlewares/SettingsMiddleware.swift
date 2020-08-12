//
//  SettingsMiddleware.swift
//  Bouncer
//
//  Created by Daniel Bernal on 8/12/20.
//

import Foundation
import Combine

func settingsMiddleware(appSettings: AppSettingsStore) -> Middleware<AppState, AppAction> {

    var settings = appSettings
    return { state, action in
        switch action {

            case .settings(action: .fetchSettings):
                return Just(AppAction.settings(action:
                    .updateStateFromSettings(hasLaunchedApp: appSettings.hasLaunchedApp,
                                             NumberOfLaunches: appSettings.numberOfLaunches,
                                             lastVersionPromptedForReview: appSettings.lastVersionPromptedForReview)))
                    .eraseToAnyPublisher()

            case .settings(action: .setHasLaunchedApp):
                settings.hasLaunchedApp = true

            case .settings(action: .setLastVersionPromptedForReview(let version)):
                settings.lastVersionPromptedForReview = version

            case .settings(action: .setNumberOfLaunches(let launches)):
                settings.numberOfLaunches = launches

            default:
                break

        }
        return Empty().eraseToAnyPublisher()
    }
}
