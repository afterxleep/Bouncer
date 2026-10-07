//
//  FilterStoreExtensionSafetyTests.swift
//  BouncerTests
//
//  Unreadable rules must stay on disk for recovery in both processes.
//
//

import XCTest
import Combine
@testable import Bouncer

final class FilterStoreExtensionSafetyTests: XCTestCase {

    var filterStore = FilterStoreFile()
    var cancellables = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "Reset Filters")
        _ = filterStore.reset()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
    }

    override func tearDown() {
        _ = filterStore.reset()
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Helpers

    private func awaitPublisher<T, E: Error>(
        _ publisher: AnyPublisher<T, E>,
        timeout: TimeInterval = 2
    ) -> Result<T, E>? {
        let expectation = self.expectation(description: "Await publisher")
        var captured: Result<T, E>?
        _ = publisher.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    captured = .failure(error)
                    expectation.fulfill()
                }
            },
            receiveValue: { value in
                if captured == nil {
                    captured = .success(value)
                    expectation.fulfill()
                }
            }
        )
        waitForExpectations(timeout: timeout, handler: nil)
        return captured
    }

    private func quarantineFiles() -> [URL] {
        guard let dir = FilterStoreFile.fileURL?.deletingLastPathComponent() else {
            return []
        }
        let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return names
            .filter { $0.hasPrefix("filters.json.corrupt-") }
            .map { dir.appendingPathComponent($0) }
    }

    // MARK: - B3: extension path must not destroy the store

    /// The MessageFilterExtension process has no UI to show an alert on, so
    /// it must use the preserve policy: the on-disk bytes must be untouched
    /// after a fetch on a corrupt file, and no quarantine sidecar must be
    /// created. Before the fix, every fetch() call from the extension
    /// silently overwrote the corrupt file with `[]`, losing every rule.
    func test_ExtensionFetchLeavesCorruptFileUntouched() throws {
        guard let url = FilterStoreFile.fileURL else {
            XCTFail("filter store URL unavailable in test environment")
            return
        }
        let garbage = Data("not a rule list at all".utf8)
        try garbage.write(to: url)
        let existingSidecars = Set(quarantineFiles())

        let result = awaitPublisher(filterStore.fetch(policy: .preserve))
        XCTAssertNotNil(result, "fetch(policy: .preserve) never resolved on a corrupt file")
        if case .failure(let error)? = result {
            switch error {
            case .loadError:
                break
            default:
                XCTFail("Expected .loadError on corrupt file, got \(error)")
            }
        } else {
            XCTFail("Expected .failure on corrupt file under preserve policy")
        }

        let onDisk = try Data(contentsOf: url)
        XCTAssertEqual(onDisk, garbage,
                       "filters.json was modified by fetch(policy: .preserve); the extension must never write to the store")

        XCTAssertEqual(Set(quarantineFiles()), existingSidecars,
                      "fetch(policy: .preserve) created a quarantine sidecar; preserve policy must be strictly read-only")
    }

    func test_AppFetchLeavesUnreadableBytesAndSidecarsUntouched() throws {
        guard let url = FilterStoreFile.fileURL else {
            XCTFail("filter store URL unavailable in test environment")
            return
        }

        let garbage = Data("{ \"phrase\": broken json, no closing brace".utf8)
        try garbage.write(to: url)
        let existingSidecars = Set(quarantineFiles())

        let result = awaitPublisher(filterStore.fetch())
        if case .failure(.loadError)? = result {
            // The app can report the read error without changing the store.
        } else {
            XCTFail("Expected .loadError for unreadable rules")
        }

        let onDisk = try Data(contentsOf: url)
        XCTAssertEqual(onDisk, garbage)
        XCTAssertEqual(Set(quarantineFiles()), existingSidecars)
    }

    func test_AppFetchReportsUnreadableRulesAfterRelaunch() throws {
        guard let url = FilterStoreFile.fileURL else {
            XCTFail("filter store URL unavailable in test environment")
            return
        }
        let original = Data("garbage".utf8)
        try original.write(to: url)

        let first = awaitPublisher(filterStore.fetch())
        if case .failure(.loadError)? = first {
            // The first launch reports the unreadable file.
        } else {
            XCTFail("First launch must report .loadError")
        }

        let second = awaitPublisher(FilterStoreFile().fetch())
        if case .failure(.loadError)? = second {
            // Repeated launch cannot silently replace the original bytes.
        } else {
            XCTFail("Second launch must still report .loadError")
        }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }
}
