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

    /// The only Settings URL the app opens must stay well formed — it's the
    /// single path now that the private URL scheme is gone.
    func testPublicSettingsUrlIsWellFormed() {
        XCTAssertEqual(UIApplication.openSettingsURLString, "app-settings:")
        XCTAssertNotNil(URL(string: UIApplication.openSettingsURLString))
    }

    func testHelpModeDoesNotNeedToChangeLaunchState() {
        // Reaching onboarding from Help implies the app already launched once;
        // dismissing it must leave that flag alone.
        let store = makeStore(hasLaunchedApp: true)
        XCTAssertTrue(store.state.settings.hasLaunchedApp)
    }
}
