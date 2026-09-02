//
//  RatingServiceDefault.swift
//  Bouncer
//

import Foundation
import StoreKit

struct ReviewServiceStoreKit: ReviewService {

    let launchesMultipleRqeuired: Int = 10
    var appSettings: AppSettingsStore

    /// Lookup for the current CFBundleVersion. A missing or non-string value
    /// makes the review prompt a no-op — the prompt is a nice-to-have, and
    /// crashing the app on a recoverable configuration miss is not.
    var bundleVersion: () -> String? = {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }

    init(appSettings: AppSettingsStore) {
        self.appSettings = appSettings
    }

    mutating func requestReview() {
        guard let currentVersion = bundleVersion(), !currentVersion.isEmpty else {
            return
        }

        let lastVersionPromptedForReview = appSettings.lastVersionPromptedForReview

        // Has the process been completed several times and the user has not already been prompted for this version?
        // The launch count must clear the threshold before the modulo means
        // anything — at zero launches `0 % 10` is also 0, which asked brand new
        // users to rate the app the first time they added a rule.
        let launches = appSettings.numberOfLaunches
        if launches >= launchesMultipleRqeuired,
           launches % launchesMultipleRqeuired == 0,
           currentVersion != lastVersionPromptedForReview {
            appSettings.lastVersionPromptedForReview = currentVersion

            if #available(iOS 14.0, *) {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                }
            } else {
                SKStoreReviewController.requestReview()
            }
        }
    }

}
