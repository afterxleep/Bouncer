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
                // TODO: The problem with dispatching these actions is that the middleware will then
                // re-run them.  Let's figure out a more elegant way to do this
                let hasLaunched = Just(AppAction.settings(action:
                                            .setHasLaunchedApp(status: appSettings.hasLaunchedApp)))
                let numberOfLaunches = Just(AppAction.settings(action:
                                            .setNumberOfLaunches(number: appSettings.numberOfLaunches)))
                let lastVersion = Just(AppAction.settings(action:
                                            .setLastVersionPromptedForReview(version: appSettings.lastVersionPromptedForReview)))
                return hasLaunched.merge(with: numberOfLaunches, lastVersion).eraseToAnyPublisher()

            case .settings(action: .setHasLaunchedApp(let status)):
                settings.hasLaunchedApp = status

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
