//
//  OnboardingCompletionTests.swift
//  BouncerTests
//

import XCTest
import UIKit
@testable import Bouncer

/// Covers the state path onboarding drives: finishing it must flip
/// `hasLaunchedApp`, which is what `BaseView` switches on. Opening Settings
/// from step 1 must not.
final class OnboardingCompletionTests: XCTestCase {

    private func makeStore(hasLaunchedApp: Bool = false) -> AppStore {
        AppStore(
            initialState: AppState(
                settings: SettingsState(hasLaunchedApp: hasLaunchedApp),
                filters: FilterState()
            ),
            reducer: appReducer
        )
    }

    func testStoreStartsWithOnboardingPending() {
        XCTAssertFalse(makeStore().state.settings.hasLaunchedApp)
    }

    func testFinishingOnboardingMarksTheAppAsLaunched() {
        let store = makeStore()
        store.dispatch(AppAction.settings(action: .setHasLaunchedApp(status: true)))
        XCTAssertTrue(store.state.settings.hasLaunchedApp)
    }

    func testFinishingOnboardingIsIdempotent() {
        let store = makeStore()
        store.dispatch(AppAction.settings(action: .setHasLaunchedApp(status: true)))
        store.dispatch(AppAction.settings(action: .setHasLaunchedApp(status: true)))
        XCTAssertTrue(store.state.settings.hasLaunchedApp)
    }

    func testFinishingOnboardingLeavesOtherSettingsAlone() {
        let store = makeStore()
        store.dispatch(AppAction.settings(action: .setNumberOfLaunches(number: 7)))
        store.dispatch(AppAction.settings(action: .setDatabaseVersion(version: 3)))
        store.dispatch(AppAction.settings(action: .setHasLaunchedApp(status: true)))

        XCTAssertTrue(store.state.settings.hasLaunchedApp)
        XCTAssertEqual(store.state.settings.numberOfLaunches, 7)
        XCTAssertEqual(store.state.settings.databaseVersion, 3)
    }

    func testFinishingOnboardingLeavesFiltersUntouched() {
        let store = makeStore()
        let filter = Filter(id: UUID(), phrase: "test", type: .any, action: .junk)
        store.dispatch(AppAction.filter(action: .fetchComplete(filters: [filter])))
        XCTAssertEqual(store.state.filters.filters, [filter])

        store.dispatch(AppAction.settings(action: .setHasLaunchedApp(status: true)))

        XCTAssertTrue(store.state.settings.hasLaunchedApp)
        XCTAssertEqual(store.state.filters.filters, [filter])
    }

    /// Opening Settings from step 1 is deliberately not a completion:
    /// the user still has four steps to walk through when they come back.
    func testOpeningSettingsDoesNotCompleteOnboarding() {
        let store = makeStore()
        // The container's onOpenSettings dispatches nothing at all.
        XCTAssertFalse(store.state.settings.hasLaunchedApp)
    }

    /// `SystemSettings.open()` must ask UIKit to open the public Settings URL —
    /// not the private `App-Prefs:` scheme we dropped. The previous test only
    /// asserted that UIKit's constant is well formed; nothing exercised the
    /// app's own call, so reverting `open()` to the private scheme slipped
    /// past it. This swaps in a recording opener and asserts on the URL it
    /// was asked to open.
    func testSystemSettingsOpensThePublicSettingsUrl() {
        let spy = RecordingSettingsOpener()
        let previous = SystemSettings.opener
        SystemSettings.opener = spy
        defer { SystemSettings.opener = previous }

        SystemSettings.open()

        XCTAssertEqual(spy.openedURLs, [URL(string: UIApplication.openSettingsURLString)])
        XCTAssertEqual(spy.openedURLs.first?.absoluteString, UIApplication.openSettingsURLString)
        XCTAssertNotEqual(spy.openedURLs.first?.absoluteString, "App-Prefs:",
                          "Private App-Prefs scheme must not be used to launch Settings")
    }

    func testHelpModeDoesNotNeedToChangeLaunchState() {
        // Reaching onboarding from Help implies the app already launched once;
        // dismissing it must leave that flag alone.
        let store = makeStore(hasLaunchedApp: true)
        XCTAssertTrue(store.state.settings.hasLaunchedApp)
    }
}

private final class RecordingSettingsOpener: SystemSettingsOpening {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any]) {
        openedURLs.append(url)
    }
}
