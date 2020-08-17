//
//  AppSettingsDefaultsTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

struct TestSetting<T: Equatable> {
    var name: String
    var testValue: T
}

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
        appSettingsA.hasLaunchedApp = true
        XCTAssertEqual(appSettingsB.hasLaunchedApp, true)
    }

    func testLastVersionPromptedForReview() {
        let version = Int.random(in: 1..<10000)
        appSettingsA.lastVersionPromptedForReview = "\(version)"
        XCTAssertEqual(appSettingsB.lastVersionPromptedForReview, "\(version)")
    }

    func testNumberOfLaunches() {
        let launches = Int.random(in: 1..<10000)
        appSettingsA.numberOfLaunches = launches
        XCTAssertEqual(appSettingsB.numberOfLaunches, launches)
    }


}

