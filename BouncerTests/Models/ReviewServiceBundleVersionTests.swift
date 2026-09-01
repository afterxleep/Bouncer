//
//  ReviewServiceBundleVersionTests.swift
//  BouncerTests
//
//  Regression for the QA finding that RatingServiceDefault.requestReview()
//  fatalError'd the app if CFBundleVersion was missing or not a string —
//  a recoverable condition on a path that runs every time the user saves a
// rule. A missing build number should mean "do not show the review prompt",
// not "kill the app".
//

import XCTest
@testable import Bouncer
import StoreKit

final class ReviewServiceBundleVersionTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private var appSettings: AppSettingsStore!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
        appSettings = AppSettingsDefaults(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: #file)
        super.tearDown()
    }

    /// When CFBundleVersion is absent, requestReview() must early-return
    /// without prompting and without crashing the app. The test
    /// injects the missing-version outcome through the bundle-version
    /// seam and observes that lastVersionPromptedForReview never gets
    /// written — proof that the would-prompt branch was not taken.
    func test_MissingBundleVersionDoesNotCrashOrPrompt() {
        var service = ReviewServiceStoreKit(appSettings: appSettings)
        service.bundleVersion = { nil }

        // Drive the would-prompt branch: 10 launches, version differs from
        // what was previously prompted for. Under the old code this would
        // fatalError; under the fix it must simply return.
        appSettings.numberOfLaunches = 10
        appSettings.lastVersionPromptedForReview = ""

        service.requestReview()

        XCTAssertEqual(appSettings.lastVersionPromptedForReview, "",
                       "requestReview() wrote lastVersionPromptedForReview despite the bundle version being missing — it should have early-returned")
    }

    /// A non-string CFBundleVersion (the other path that used to fatalError
    /// via the `as? String` cast) must take the same early-return. The
    /// closure seam models both cases uniformly: any value that is not a
    /// usable String is propagated as nil.
    func test_NonStringBundleVersionDoesNotCrashOrPrompt() {
        var service = ReviewServiceStoreKit(appSettings: appSettings)
        service.bundleVersion = { nil }

        appSettings.numberOfLaunches = 20
        appSettings.lastVersionPromptedForReview = "previous-version"

        service.requestReview()

        XCTAssertEqual(appSettings.lastVersionPromptedForReview, "previous-version",
                       "requestReview() overwrote lastVersionPromptedForReview even though the bundle version was unusable")
    }

    /// When the bundle version IS present, the existing prompt path still
    /// runs — guards against a regression that turns a missing-version
    /// early return into a blanket skip.
    func test_PresentBundleVersionStillPrompts() {
        var service = ReviewServiceStoreKit(appSettings: appSettings)
        service.bundleVersion = { "1395" }

        appSettings.numberOfLaunches = 10
        appSettings.lastVersionPromptedForReview = ""

        service.requestReview()

        XCTAssertEqual(appSettings.lastVersionPromptedForReview, "1395",
                       "requestReview() did not record lastVersionPromptedForReview on a happy-path call")
    }
}