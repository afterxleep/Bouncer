//
//  AnalyticsEventTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

final class AnalyticsEventTests: XCTestCase {

    private func rule(_ phrase: String, _ action: FilterDestination, _ sub: FilterDestination = .none) -> Filter {
        Filter(id: UUID(), phrase: phrase, type: .sender, action: action, subAction: sub, caseSensitive: true)
    }

    func testEventNamesAreSnakeCaseAndUnique() {
        let events: [AnalyticsEvent] = [
            .appLaunched(launchNumber: 1, installType: .newInstall, daysSinceFirstSeen: 0, onboardingCompleted: false),
            .ruleLibrarySnapshot(RuleLibraryStats(filters: [])),
            .privacyChoiceMade(.granted, source: .privacySheet),
            .onboardingStarted, .onboardingStepViewed(step: 1, mode: .firstRun), .onboardingBackTapped(fromStep: 2),
            .onboardingSettingsOpened(step: 1), .onboardingSkipped, .onboardingCompleted(mode: .firstRun),
            .onboardingClosed(step: 3), .supportRequested(source: .help, mailAvailable: true),
            .ruleLaneChanged(lane: .junk, laneRuleCount: 1), .ruleSearchStarted(lane: .allow),
            .addRuleTapped(source: .toolbar, lane: .junk), .ruleOpened(rule("a", .junk)),
            .ruleDeleteTapped(.swipe), .helpOpened(source: .libraryMenu), .helpActionTapped(.walkthrough),
            .ruleEditorOpened(.add), .ruleEditorCancelled, .ruleCategoryPickerOpened, .ruleDestinationSelected(destination: "junk"),
            .ruleOptionToggled(.regex, enabled: true), .ruleAdvancedToggled(expanded: true), .regexHelpOpened,
            .ruleCreated(rule("a", .junk), ruleCountAfter: 1), .ruleUpdated(rule("a", .junk)),
            .ruleDeleted(rule("a", .junk), ruleCountAfter: 0), .importStarted,
            .importFileParsed(ruleCount: 1, newRuleCount: 1), .importSelectionChanged(.all), .importCancelled,
            .rulesImported(RuleLibraryStats(filters: [])), .errorShown(kind: "disk_error"),
        ]
        let names = events.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "two events share a name")
        for name in names {
            XCTAssertNotNil(name.range(of: "^[a-z]+(_[a-z]+)*$", options: .regularExpression), name)
        }
    }

    func testRuleShapeUsesTheMostSpecificDestination() {
        let props = rule("hello", .promotion, .promotionOffers).analyticsProperties
        XCTAssertEqual(props["action"], "promotion")
        XCTAssertEqual(props["destination"], "promotionOffers")
        XCTAssertEqual(props["lane"], "categories")
        XCTAssertEqual(props["match_type"], "sender")
        XCTAssertEqual(props["case_sensitive"], true)
        XCTAssertEqual(props["phrase_length"], 5)
    }

    func testJunkRulesFallBackToTheirAction() {
        XCTAssertEqual(rule("x", .junk).analyticsProperties["destination"], "junk")
    }

    func testLibraryStatsCountEachLane() {
        let stats = RuleLibraryStats(filters: [
            rule("a", .junk), rule("b", .allow, .allow), rule("c", .transaction, .transactionOrder),
        ])
        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.junk, 1)
        XCTAssertEqual(stats.allow, 1)
        XCTAssertEqual(stats.categories, 1)
        XCTAssertEqual(stats.caseSensitive, 3)
    }

    func testFirstLaunchFlagNeedsANewInstall() {
        let fresh = AnalyticsEvent.appLaunched(launchNumber: 1, installType: .newInstall, daysSinceFirstSeen: 0, onboardingCompleted: false)
        let upgraded = AnalyticsEvent.appLaunched(launchNumber: 1, installType: .existingUser, daysSinceFirstSeen: 0, onboardingCompleted: true)
        XCTAssertEqual(fresh.properties["is_first_launch"], true)
        XCTAssertEqual(upgraded.properties["is_first_launch"], false)
    }

    func testErrorKindsCarryNoMessageText() {
        XCTAssertEqual(FilterError.invalidRegex("secret").analyticsKind, "invalid_regex")
        XCTAssertEqual(FilterError.diskError(message: "/Users/me/file").analyticsKind, "disk_error")
    }

    func testPropertiesConvertToPlainValuesForTheSDK() {
        let sdk: [String: Any] = ["s": .string("x"), "i": .int(2), "b": .bool(true)].sdkRepresentation
        XCTAssertEqual(sdk["s"] as? String, "x")
        XCTAssertEqual(sdk["i"] as? Int, 2)
        XCTAssertEqual(sdk["b"] as? Bool, true)
    }
}
