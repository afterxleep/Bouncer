//
//  RatingServiceDefault.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/11/20.
//

import Foundation
import StoreKit

struct RatingServiceStoreKit: RatingService {
    
    var launchesRequired: Int = 3
    let userSettings: UserSettings
    
    
    init(userSettings: UserSettings = UserSettingsDefaults()) {
        self.userSettings = userSettings
    }
    
    func requestReview() {
        // Get the current bundle version for the app
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary") }
        
        let lastVersionPromptedForReview = userSettings.lastVersionPromptedForReview

        print(userSettings.numberOfLaunches)
        
        // Has the process been completed several times and the user has not already been prompted for this version?
        if userSettings.numberOfLaunches >= launchesRequired && currentVersion != lastVersionPromptedForReview {
            SKStoreReviewController.requestReview()
        }

    }
    
}
