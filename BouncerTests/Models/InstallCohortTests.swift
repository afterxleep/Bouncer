//
//  InstallCohortTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

final class InstallCohortTests: XCTestCase {

    private var defaults: UserDefaults!
    private var store: InstallCohortStore!
    private let day: TimeInterval = 86_400
    private let installDate = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
        let suite = "InstallCohortTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        store = InstallCohortStore(userDefaults: defaults)
    }

    func testNoPriorUseIsANewInstall() {
        let cohort = store.resolve(numberOfLaunches: 0, hasLaunchedApp: false, now: installDate)
        XCTAssertEqual(cohort, InstallCohort(installType: .newInstall, firstSeenAt: installDate))
    }

    func testPriorLaunchesMeanAnExistingUser() {
        let cohort = store.resolve(numberOfLaunches: 12, hasLaunchedApp: true, now: installDate)
        XCTAssertEqual(cohort.installType, .existingUser)
    }

    func testFinishedOnboardingAloneMeansAnExistingUser() {
        let cohort = store.resolve(numberOfLaunches: 0, hasLaunchedApp: true, now: installDate)
        XCTAssertEqual(cohort.installType, .existingUser)
    }

    func testTheVerdictSurvivesLaterLaunches() {
        _ = store.resolve(numberOfLaunches: 0, hasLaunchedApp: false, now: installDate)

        let later = store.resolve(numberOfLaunches: 30, hasLaunchedApp: true, now: installDate.addingTimeInterval(20 * day))

        XCTAssertEqual(later, InstallCohort(installType: .newInstall, firstSeenAt: installDate))
    }

    func testTheVerdictSurvivesARecreatedStore() {
        _ = store.resolve(numberOfLaunches: 5, hasLaunchedApp: true, now: installDate)
        let again = InstallCohortStore(userDefaults: defaults)
            .resolve(numberOfLaunches: 0, hasLaunchedApp: false, now: installDate.addingTimeInterval(day))
        XCTAssertEqual(again.installType, .existingUser)
        XCTAssertEqual(again.firstSeenAt, installDate)
    }

    func testDaysSinceFirstSeenCountsWholeDays() {
        let cohort = InstallCohort(installType: .newInstall, firstSeenAt: installDate)
        XCTAssertEqual(cohort.daysSinceFirstSeen(now: installDate.addingTimeInterval(3 * day + 100)), 3)
        XCTAssertEqual(cohort.daysSinceFirstSeen(now: installDate.addingTimeInterval(-day)), 0)
    }

    func testStageProgressesFromFirstLaunchToReturning() {
        let cohort = InstallCohort(installType: .newInstall, firstSeenAt: installDate)
        XCTAssertEqual(cohort.stage(launchNumber: 1, now: installDate), .firstLaunch)
        XCTAssertEqual(cohort.stage(launchNumber: 2, now: installDate.addingTimeInterval(day)), .newUser)
        XCTAssertEqual(cohort.stage(launchNumber: 9, now: installDate.addingTimeInterval(7 * day)), .returning)
    }

    func testPreAnalyticsUsersAreAlwaysReturning() {
        let cohort = InstallCohort(installType: .existingUser, firstSeenAt: installDate)
        XCTAssertEqual(cohort.stage(launchNumber: 1, now: installDate), .returning)
    }
}
