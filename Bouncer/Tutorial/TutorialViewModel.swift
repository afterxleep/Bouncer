//
//  WelcomeViewModel.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import Foundation

final class TutorialViewModel: ObservableObject {
    
    let userSettings = UserSettingsDefaults()
    
    func firstLaunchCompleted() {
        userSettings.hasLaunchedApp = true
    }
    
}


