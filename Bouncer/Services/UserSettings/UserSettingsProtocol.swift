//
//  UserSettings.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/1/20.
//

import Foundation

protocol UserSettingsProtocol {
    var hasLaunchedApp: Bool { get set }
    var numberOfLaunches: Int { get set }
    var lastVersionPromptedForReview: String { get set }
}
