//
//  AppAction.swift
//  Bouncer
//

import Foundation

enum AppAction {
    case filter(action: FilterAction)
    case settings(action: SettingsAction)
    case none
}
