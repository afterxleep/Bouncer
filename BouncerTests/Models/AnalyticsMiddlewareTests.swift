//
//  AnalyticsMiddlewareTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

final class AnalyticsMiddlewareTests: XCTestCase {

    private let launchDate = Date(timeIntervalSince1970: 1_700_000_000)
    private var spy: SpyAnalyticsTracker!

    override func setUp() {
        super.setUp()
        spy = SpyAnalyticsTracker()
    }

    private func makeStore(consent: AnalyticsConsent = .granted,
                           filters: [Filter] = [],
                           installType: InstallType = .newInstall,
                           launchNumber: Int = 1,
                           onboardingCompleted: Bool = false) -> AppStore {
        let launch = AnalyticsLaunchContext(
            cohort: InstallCohort(installType: installType, firstSeenAt: launchDate),
            launchNumber: launchNumber,
            onboardingCompleted: onboardingCompleted,
            appVersion: "2.9.1 (1)"
        )
        return AppStore(
            initialState: AppState(
                settings: SettingsState(hasLaunchedApp: onboardingCompleted, analyticsConsent: consent),
                filters: FilterState(filters: filters)
            ),
            reducer: appReducer,
            middlewares: [analyticsMiddleware(tracker: spy, launch: launch, now: { self.launchDate })]
        )
    }

    private func rule(_ phrase: String = "free prize",
                      action: FilterDestination = .junk,
                      subAction: FilterDestination = .none,
                      regex: Bool = false) -> Filter {
        Filter(id: UUID(), phrase: phrase, type: .message, action: action, subAction: subAction, useRegex: regex)
    }

    // MARK: - Launch

    func testLaunchWithConsentReportsAppLaunchedAndRegistersTheCohort() {
        let store = makeStore(installType: .newInstall, launchNumber: 1)

        store.dispatch(.settings(action: .appLaunched))

        XCTAssertEqual(spy.events, [
            .appLaunched(launchNumber: 1, installType: .newInstall, daysSinceFirstSeen: 0, onboardingCompleted: false)
        ])
        let registered = spy.registered.reduce(into: AnalyticsProperties()) { $0.merge($1) { $1 } }
        XCTAssertEqual(registered["install_type"], "new_install")
        XCTAssertEqual(registered["user_stage"], "first_launch")
        XCTAssertEqual(registered["launch_count"], 1)
        XCTAssertEqual(registered["app_version"], "2.9.1 (1)")
    }

    func testLaunchWithoutAnAnswerReportsNothing() {
        let store = makeStore(consent: .unknown)
        store.dispatch(.settings(action: .appLaunched))
        XCTAssertTrue(spy.events.isEmpty)
        XCTAssertTrue(spy.registered.isEmpty)
    }

    func testLaunchAfterDecliningReportsNothing() {
        let store = makeStore(consent: .denied)
        store.dispatch(.settings(action: .appLaunched))
        XCTAssertTrue(spy.events.isEmpty)
    }

    func testExistingUserIsMarkedReturning() {
        let store = makeStore(installType: .existingUser, launchNumber: 42, onboardingCompleted: true)
        store.dispatch(.settings(action: .appLaunched))

        let registered = spy.registered.reduce(into: AnalyticsProperties()) { $0.merge($1) { $1 } }
        XCTAssertEqual(registered["install_type"], "existing_user")
        XCTAssertEqual(registered["user_stage"], "returning")
        XCTAssertEqual(spy.events.first?.properties["is_first_launch"], false)
    }

    // MARK: - Consent changes

    func testGrantingConsentLateReportsTheLaunchAndTheLibraryOnce() {
        let store = makeStore(consent: .unknown, filters: [rule(), rule("mum", action: .allow, subAction: .allow)])
        store.dispatch(.settings(action: .appLaunched))

        store.dispatch(.settings(action: .setAnalyticsConsent(.granted)))

        XCTAssertEqual(spy.collectionStates, [true])
        XCTAssertEqual(spy.names, ["app_launched", "rule_library_snapshot"])
        XCTAssertEqual(spy.events(named: "rule_library_snapshot").first?.properties["rule_count"], 2)
    }

    func testDecliningStopsCollection() {
        let store = makeStore(consent: .granted)
        store.dispatch(.settings(action: .setAnalyticsConsent(.denied)))
        XCTAssertEqual(spy.collectionStates, [false])
    }

    func testRegrantingInTheSameSessionDoesNotRepeatTheLaunchEvent() {
        let store = makeStore(consent: .granted)
        store.dispatch(.settings(action: .appLaunched))
        store.dispatch(.settings(action: .setAnalyticsConsent(.denied)))
        store.dispatch(.settings(action: .setAnalyticsConsent(.granted)))

        XCTAssertEqual(spy.events(named: "app_launched").count, 1)
        XCTAssertEqual(spy.collectionStates, [false, true])
        XCTAssertGreaterThanOrEqual(spy.registered.count, 2, "profile is re-registered after a reset")
    }

    // MARK: - Library

    func testFirstLoadOfTheLibraryReportsASnapshotOncePerSession() {
        let store = makeStore()
        store.dispatch(.settings(action: .appLaunched))
        let loaded = [rule(), rule("a", regex: true), rule("b", action: .allow, subAction: .allow),
                      rule("c", action: .promotion, subAction: .promotionOffers)]

        store.dispatch(.filter(action: .fetchComplete(filters: loaded)))
        store.dispatch(.filter(action: .fetchComplete(filters: loaded)))

        let snapshots = spy.events(named: "rule_library_snapshot")
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.properties["rule_count"], 4)
        XCTAssertEqual(snapshots.first?.properties["junk_rule_count"], 2)
        XCTAssertEqual(snapshots.first?.properties["allow_rule_count"], 1)
        XCTAssertEqual(snapshots.first?.properties["category_rule_count"], 1)
        XCTAssertEqual(snapshots.first?.properties["regex_rule_count"], 1)
    }

    func testEveryLoadRefreshesTheRegisteredRuleCount() {
        let store = makeStore()
        store.dispatch(.settings(action: .appLaunched))

        store.dispatch(.filter(action: .fetchComplete(filters: [rule(), rule("x")])))

        XCTAssertEqual(spy.registered.last?["rule_count"], 2)
    }

    // MARK: - Rule changes

    func testAddingARuleReportsItsShapeAndTheNewTotal() {
        let store = makeStore(filters: [rule("existing")])
        let added = rule("secret phrase", action: .promotion, subAction: .promotionCoupons, regex: true)

        store.dispatch(.filter(action: .add(filter: added)))

        XCTAssertEqual(spy.events, [.ruleCreated(added, ruleCountAfter: 2)])
        let props = spy.events[0].properties
        XCTAssertEqual(props["destination"], "promotionCoupons")
        XCTAssertEqual(props["lane"], "categories")
        XCTAssertEqual(props["uses_regex"], true)
        XCTAssertEqual(props["phrase_length"], 13)
    }

    func testNoEventEverCarriesTheRulePhrase() {
        let phrase = "ZXQ-unique-phrase"
        let added = rule(phrase)
        let store = makeStore(filters: [added])

        store.dispatch(.filter(action: .add(filter: rule(phrase))))
        store.dispatch(.filter(action: .update(filter: added)))
        store.dispatch(.filter(action: .delete(uuid: added.id)))
        store.dispatch(.filter(action: .addMany(filters: [rule(phrase)])))

        for event in spy.events {
            for value in event.properties.values {
                XCTAssertNotEqual(value, .string(phrase), "\(event.name) leaked the phrase")
            }
        }
    }

    func testUpdatingARuleReportsItsShape() {
        let existing = rule()
        let store = makeStore(filters: [existing])
        store.dispatch(.filter(action: .update(filter: existing)))
        XCTAssertEqual(spy.events, [.ruleUpdated(existing)])
    }

    func testDeletingARuleReportsItsShapeAndTheRemainingTotal() {
        let doomed = rule("doomed")
        let store = makeStore(filters: [doomed, rule("kept")])

        store.dispatch(.filter(action: .delete(uuid: doomed.id)))

        XCTAssertEqual(spy.events, [.ruleDeleted(doomed, ruleCountAfter: 1)])
    }

    func testDeletingAnUnknownRuleReportsNothing() {
        let store = makeStore(filters: [rule()])
        store.dispatch(.filter(action: .delete(uuid: UUID())))
        XCTAssertTrue(spy.events.isEmpty)
    }

    // MARK: - Import

    func testParsingAnImportFileReportsHowManyRulesAreNew() {
        let known = rule("known")
        let store = makeStore(filters: [known])

        store.dispatch(.filter(action: .decodeComplete(filters: [known, rule("fresh"), rule("fresher")])))

        XCTAssertEqual(spy.events, [.importFileParsed(ruleCount: 3, newRuleCount: 2)])
    }

    func testConfirmingAnImportReportsWhatWasChosen() {
        let store = makeStore()
        let chosen = [rule("a"), rule("b", action: .allow, subAction: .allow)]

        store.dispatch(.filter(action: .addMany(filters: chosen)))

        XCTAssertEqual(spy.events, [.rulesImported(RuleLibraryStats(filters: chosen))])
        XCTAssertEqual(spy.events.first?.properties["imported_count"], 2)
    }

    // MARK: - Errors

    func testErrorsAreReportedByKindWithoutTheirMessage() {
        let store = makeStore()

        store.dispatch(.filter(action: .error(.invalidRegex("Unclosed group near 'secret'"))))

        XCTAssertEqual(spy.events, [.errorShown(kind: "invalid_regex")])
    }

    func testStoreFailuresAreReported() {
        let store = makeStore()
        store.dispatch(.filter(action: .addError(error: .addError)))
        XCTAssertEqual(spy.events, [.errorShown(kind: "save_failed")])
    }
}
