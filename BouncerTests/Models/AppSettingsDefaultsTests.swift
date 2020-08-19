//
//  AppSettingsDefaultsTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

class AppSettingsDefaultsTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private var appSettingsA: AppSettingsStore!
    private var appSettingsB: AppSettingsStore!

    override func setUp() {
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
        appSettingsA = AppSettingsDefaults(userDefaults: userDefaults)
        appSettingsB = AppSettingsDefaults(userDefaults: userDefaults)
        super.setUp()
    }

    func testHastLaunchedApp() {
        XCTAssertEqual(appSettingsA.hasLaunchedApp, false)
        appSettingsA.hasLaunchedApp = true
        XCTAssertEqual(appSettingsB.hasLaunchedApp, true)
    }

    func testLastVersionPromptedForReview() {
        XCTAssertEqual(appSettingsA.lastVersionPromptedForReview, "")
        let version = Int.random(in: 1..<10000)
        appSettingsA.lastVersionPromptedForReview = "\(version)"
        XCTAssertEqual(appSettingsB.lastVersionPromptedForReview, "\(version)")
    }

    func testNumberOfLaunches() {
        XCTAssertEqual(appSettingsA.numberOfLaunches, 0)
        let launches = Int.random(in: 1..<10000)
        appSettingsA.numberOfLaunches = launches
        XCTAssertEqual(appSettingsB.numberOfLaunches, launches)
    }


}

