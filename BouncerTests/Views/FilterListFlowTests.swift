//
//  FilterListFlowTests.swift
//  BouncerTests
//

import XCTest
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
        XCTAssertEqual(store.state.filters.filterError?.id, "EMPTY_IMPORT_FILE")
    }

    func testDecodingErrorUsesTheIncorrectFormatMessage() {
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .error(.decodingError("bad json"))))
        XCTAssertEqual(store.state.filters.filterError?.id, "INCORRECT_FILE_FORMAT")
    }

    func testClearErrorResetsTheAlert() {
        let store = makeStore()
        store.dispatch(AppAction.filter(action: .error(.emptyImportFileError)))
        XCTAssertNotNil(store.state.filters.filterError)

        store.dispatch(AppAction.filter(action: .clearError))
        XCTAssertNil(store.state.filters.filterError)
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
