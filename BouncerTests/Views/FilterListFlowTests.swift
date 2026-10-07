//
//  FilterListFlowTests.swift
//  BouncerTests
//

import XCTest
import UIKit
import SwiftUI
@testable import Bouncer

/// Covers the Rules-list state transitions that the UI drives: listing,
/// category filtering, search, and the import pipeline (whose file-picker
/// stage cannot be driven from an automated simulator session).
final class FilterListFlowTests: XCTestCase {

    private func makeStore(filters: [Filter] = []) -> AppStore {
        AppStore(
            initialState: AppState(
                settings: SettingsState(hasLaunchedApp: true),
                filters: FilterState(filters: filters)
            ),
            reducer: appReducer
        )
    }

    private func filter(_ phrase: String,
                        _ action: FilterDestination = .junk,
                        type: FilterType = .any) -> Filter {
        Filter(id: UUID(), phrase: phrase, type: type, action: action)
    }

    // MARK: - Listing

    func testFetchCompletePopulatesTheList() {
        let store = makeStore()
        let filters = [filter("spam"), filter("bank", .transaction)]
        store.dispatch(AppAction.filter(action: .fetchComplete(filters: filters)))
        XCTAssertEqual(store.state.filters.filters, filters)
    }

    func testFetchCompleteReplacesRatherThanAppends() {
        let store = makeStore(filters: [filter("old")])
        let fresh = [filter("new")]
        store.dispatch(AppAction.filter(action: .fetchComplete(filters: fresh)))
        XCTAssertEqual(store.state.filters.filters, fresh)
    }

    func testEmptyFetchClearsTheList() {
        let store = makeStore(filters: [filter("spam")])
        store.dispatch(AppAction.filter(action: .fetchComplete(filters: [])))
        XCTAssertTrue(store.state.filters.filters.isEmpty)
    }

    // MARK: - Category tabs

    func testFiltersSplitAcrossTheThreeListTabs() {
        let junk = filter("spam", .junk)
        let safe = filter("mum", .allow)
        let other = filter("order", .transaction)
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .fetchComplete(filters: [junk, safe, other])))

        let all = store.state.filters.filters
        XCTAssertEqual(all.filter { $0.action == .junk }, [junk])
        XCTAssertEqual(all.filter { $0.action == .allow }, [safe])
        XCTAssertEqual(all.filter { $0.action == .transaction }, [other])
    }

    // MARK: - Search

    func testSearchMatchesPhraseCaseInsensitively() {
        let store = makeStore()
        let filters = [filter("SPAM"), filter("bank"), filter("spammer")]
        store.dispatch(AppAction.filter(action: .fetchComplete(filters: filters)))

        let matches = store.state.filters.filters.filter {
            $0.phrase.lowercased().contains("spam")
        }
        XCTAssertEqual(matches.count, 2)
    }

    func testSearchWithNoMatchYieldsNothing() {
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .fetchComplete(filters: [filter("spam")])))
        let matches = store.state.filters.filters.filter { $0.phrase.contains("zzz") }
        XCTAssertTrue(matches.isEmpty)
    }

    // MARK: - Import pipeline

    func testDecodeCompleteStagesImportedFiltersAndFlagsProgress() {
        let store = makeStore()
        let incoming = [filter("promo"), filter("offer")]
        store.dispatch(AppAction.filter(action: .decodeComplete(filters: incoming)))

        XCTAssertEqual(store.state.filters.importedFilters, incoming)
        XCTAssertTrue(store.state.filters.filterImportInProgress)
    }

    func testImportCompletesAndClearsProgress() {
        let store = makeStore()
        let incoming = [filter("promo")]
        store.dispatch(AppAction.filter(action: .decodeComplete(filters: incoming)))
        store.dispatch(AppAction.filter(action: .import(filters: incoming)))

        XCTAssertEqual(store.state.filters.importedFilters, incoming)
        XCTAssertFalse(store.state.filters.filterImportInProgress)
    }

    func testImportErrorClearsProgressAndSurfacesTheError() {
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .decodeComplete(filters: [filter("x")])))
        XCTAssertTrue(store.state.filters.filterImportInProgress)

        store.dispatch(AppAction.filter(action: .error(.emptyImportFileError)))

        XCTAssertFalse(store.state.filters.filterImportInProgress)
        XCTAssertEqual(store.state.filters.filterError?.id, "ERROR_EMPTY_IMPORT_FILE")
    }

    func testDecodingErrorUsesTheIncorrectFormatMessage() {
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .error(.decodingFailed(reason: "bad json"))))
        XCTAssertEqual(store.state.filters.filterError?.id, "ERROR_DECODING_FAILED")
    }

    func testDiskErrorPropagatesUnderlyingMessage() {
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .error(.diskError(message: "Out of space"))))
        XCTAssertEqual(store.state.filters.filterError?.id, "ERROR_DISK")
        XCTAssertTrue(store.state.filters.filterError?.localizedMessage.contains("Out of space") ?? false,
                      "diskError message should surface the underlying disk reason, not a generic stub")
    }

    func testClearErrorResetsTheAlert() {
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .error(.emptyImportFileError)))
        XCTAssertNotNil(store.state.filters.filterError)

        store.dispatch(AppAction.filter(action: .clearError))
        XCTAssertNil(store.state.filters.filterError)
    }

    /// The file-import failure path used to call `showError`, which set an
    /// unread `@State` and let the alert disappear. The closure FilterListView
    /// receives from FilterListContainerView must dispatch the same `.error`
    /// action the reducer routes through, so a failed import actually
    /// surfaces an alert to the user.
    func testFileImportFailureSurfacesAlert() {
        let store = makeStore()
        XCTAssertNil(store.state.filters.filterError,
                     "filterError starts nil so a subsequent error is unambiguously the import")

        FilterListContainerView.show(.diskError(message: "couldn't read the file"),
                                     on: store)

        XCTAssertEqual(store.state.filters.filterError?.id, "ERROR_DISK",
                       "A file-import failure must surface a FilterError the alert binding can render")
        XCTAssertTrue(store.state.filters.filterError?.localizedMessage
                        .contains("couldn't read the file") ?? false,
                      "Disk error must carry the underlying file reason through to the user")
    }

    func testImportingLeavesTheLiveRuleListUntouchedUntilConfirmed() {
        let existing = [filter("spam")]
        let store = makeStore(filters: existing)
        store.dispatch(AppAction.filter(action: .decodeComplete(filters: [filter("promo")])))
        XCTAssertEqual(store.state.filters.filters, existing)
    }

    // MARK: - Export / import round trip

    func testFiltersSurviveAJsonRoundTrip() throws {
        let original = [
            Filter(id: UUID(), phrase: "spam", type: .any, action: .junk,
                   useRegex: false, caseSensitive: true),
            Filter(id: UUID(), phrase: "^bank", type: .sender, action: .transaction,
                   useRegex: true, caseSensitive: false)
        ]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([Filter].self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testDecodingMalformedJsonThrows() {
        let data = Data("{ not a filter list }".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode([Filter].self, from: data))
    }

    func testDecodingAnEmptyListYieldsNoFilters() throws {
        let data = Data("[]".utf8)
        let decoded = try JSONDecoder().decode([Filter].self, from: data)
        XCTAssertTrue(decoded.isEmpty)
    }
}

final class RuleListContrastTests: XCTestCase {
    private let light = UITraitCollection(userInterfaceStyle: .light)

    func testLightListTextHasReadableContrastAcrossStageAndCards() {
        let surfaces = ["top": Stage.top, "bottom": Stage.bottom, "card": Stage.card]
        let labels = ["secondary": Stage.secondary, "tertiary": Stage.tertiary]

        for (surfaceName, surface) in surfaces {
            for (labelName, label) in labels {
                XCTAssertGreaterThanOrEqual(
                    contrast(label, on: surface), 4.5,
                    "\(labelName) text on the \(surfaceName) surface must remain readable"
                )
            }
        }
    }

    func testLightRuleCategoryLabelsHaveReadableContrastOnCards() {
        let categoryTints = [
            "Junk": Brand.junk, "Safe": Brand.safe, "Orders": Brand.orders,
            "Finance": Brand.finance, "Reminders": Brand.reminders,
            "Health": Brand.health, "Offers": Brand.offers,
            "Coupons": Brand.coupons, "Promotions": Brand.promotionOther,
            "Transactions": Brand.transactionOther, "Categories": Brand.tint
        ]

        for (name, tint) in categoryTints {
            XCTAssertGreaterThanOrEqual(
                contrast(tint, on: Stage.card), 4.5,
                "\(name) label must remain readable on a rule card"
            )
        }
    }

    private func contrast(_ foreground: Color, on background: Color) -> CGFloat {
        let front = rgba(UIColor(foreground).resolvedColor(with: light))
        let back = rgba(UIColor(background).resolvedColor(with: light))
        let composed = zip(front.rgb, back.rgb).map { frontChannel, backChannel in
            frontChannel * front.alpha + backChannel * (1 - front.alpha)
        }
        let first = luminance(composed)
        let second = luminance(back.rgb)
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    private func rgba(_ color: UIColor) -> (rgb: [CGFloat], alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return ([red, green, blue], alpha)
    }

    private func luminance(_ channels: [CGFloat]) -> CGFloat {
        let linear = channels.map { channel in
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    }
}
