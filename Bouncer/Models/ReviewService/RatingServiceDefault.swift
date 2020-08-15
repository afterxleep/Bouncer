//
//  RatingServiceDefault.swift
//  Bouncer
//

import Foundation
import StoreKit

struct ReviewServiceStoreKit: ReviewService {
    
    let launchesMultipleRqeuired: Int = 3
    var appSettings: AppSettingsStore
    
    init(appSettings: AppSettingsStore) {
        self.appSettings = appSettings
    }
    
    mutating func requestReview() {
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary") }
        
        let lastVersionPromptedForReview = appSettings.lastVersionPromptedForReview
        
        // Has the process been completed several times and the user has not already been prompted for this version?
        if ((appSettings.numberOfLaunches % launchesMultipleRqeuired) == 0) && currentVersion != lastVersionPromptedForReview {
            appSettings.lastVersionPromptedForReview = currentVersion
            SKStoreReviewController.requestReview()

        }
    }
    
}
