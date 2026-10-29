//
//  AnalyticsConsentTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

final class AnalyticsConsentTests: XCTestCase {

    private var defaults: UserDefaults!
    private var settings: AppSettingsDefaults!

    override func setUp() {
        super.setUp()
        let suite = "AnalyticsConsentTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        settings = AppSettingsDefaults(userDefaults: defaults)
    }

    // MARK: - Persistence

    func testNobodyHasAnsweredOnAFreshInstall() {
        XCTAssertEqual(settings.analyticsConsent, .unknown)
    }

    func testTheAnswerIsRemembered() {
        settings.analyticsConsent = .denied
        XCTAssertEqual(AppSettingsDefaults(userDefaults: defaults).analyticsConsent, .denied)
        settings.analyticsConsent = .granted
        XCTAssertEqual(AppSettingsDefaults(userDefaults: defaults).analyticsConsent, .granted)
    }

    func testAnUnrecognisedStoredValueCountsAsUnanswered() {
        defaults.set("maybe", forKey: AppSettingsKeys.analyticsConsent.rawValue)
        XCTAssertEqual(settings.analyticsConsent, .unknown)
    }

    func testInitialStateIsSeededFromTheStoredAnswer() {
        settings.analyticsConsent = .granted
        XCTAssertEqual(SettingsState(store: settings).analyticsConsent, .granted)
    }

    // MARK: - Store wiring

    func testDispatchingAnAnswerUpdatesStateAndPersistsIt() {
        let store = AppStore(
            initialState: AppState(settings: SettingsState(store: settings), filters: FilterState()),
            reducer: appReducer,
            middlewares: [settingsMiddleware(appSettings: settings)]
        )

        store.dispatch(.settings(action: .setAnalyticsConsent(.granted)))

        XCTAssertEqual(store.state.settings.analyticsConsent, .granted)
        XCTAssertEqual(settings.analyticsConsent, .granted)
    }

    // MARK: - Gate

    func testGateBlocksEverythingUntilGranted() {
        let spy = SpyAnalyticsTracker()
        var granted = false
        let gate = ConsentGatedAnalyticsTracker(wrapped: spy, isGranted: { granted })

        gate.track(.onboardingStarted)
        gate.register(["install_type": "new_install"])
        XCTAssertTrue(spy.events.isEmpty)
        XCTAssertTrue(spy.registered.isEmpty)

        granted = true
        gate.track(.onboardingStarted)
        gate.register(["install_type": "new_install"])
        XCTAssertEqual(spy.events, [.onboardingStarted])
        XCTAssertEqual(spy.registered.count, 1)
    }

    func testGateAlwaysPassesCollectionChangesThrough() {
        let spy = SpyAnalyticsTracker()
        let gate = ConsentGatedAnalyticsTracker(wrapped: spy, isGranted: { false })
        gate.setCollectionEnabled(false)
        gate.setCollectionEnabled(true)
        XCTAssertEqual(spy.collectionStates, [false, true])
    }

    // MARK: - Copy

    func testPrivacyCopyExistsInEveryLanguage() throws {
        let keys = ["PRIVACY_TITLE", "PRIVACY_SUBTITLE", "PRIVACY_NO_TRACKING_TITLE", "PRIVACY_NO_TRACKING_BODY",
                    "PRIVACY_ON_DEVICE_TITLE", "PRIVACY_ON_DEVICE_BODY", "PRIVACY_USAGE_TITLE", "PRIVACY_USAGE_BODY",
                    "PRIVACY_ACCEPT", "PRIVACY_DECLINE", "PRIVACY_CHANGE_ANYTIME",
                    "HELP_PRIVACY_SECTION", "HELP_ANALYTICS_TOGGLE", "HELP_ANALYTICS_FOOTER"]
        let appBundle = Bundle(for: FilterStoreFile.self)
        for language in ["en", "es"] {
            let path = try XCTUnwrap(appBundle.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for key in keys {
                let value = bundle.localizedString(forKey: key, value: "<missing>", table: nil)
                XCTAssertNotEqual(value, "<missing>", "\(key) missing in \(language)")
                XCTAssertNotEqual(value, key, "\(key) untranslated in \(language)")
            }
        }
    }
}
