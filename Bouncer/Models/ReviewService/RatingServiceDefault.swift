//
//  RatingServiceDefault.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/11/20.
//

import Foundation
import StoreKit

struct ReviewServiceStoreKit: ReviewService {
    
    var launchesRequired: Int = 3
    let appSettings: AppSettingsStore
    
    init(appSettings: AppSettingsStore) {
        self.appSettings = appSettings
    }
    
    func requestReview() {
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary") }
        
        let lastVersionPromptedForReview = appSettings.lastVersionPromptedForReview
        
        // Has the process been completed several times and the user has not already been prompted for this version?
        if appSettings.numberOfLaunches >= launchesRequired && currentVersion != lastVersionPromptedForReview {
            SKStoreReviewController.requestReview()
        }
    }
    
}
