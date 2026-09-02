//
//  FilterStoreExtensionSafetyTests.swift
//  BouncerTests
//
//  Regression for the BLOCKER finding that the corrupt-store heal lives
//  inside MessageFilterExtension's fetch path: every incoming SMS triggers
//  a destructive write over filters.json. There is no UI in the extension
//  process, so a silent wipe deletes every rule the user ever wrote.
//
//  These tests pin the behaviour down:
//  - The MessageFilterExtension's fetch must never destroy or rewrite the
//    on-disk store on a decode failure.
//  - The corrupt bytes are preserved in a quarantine sidecar before the
//    app heals the store, so a partially-recoverable file can be salvaged.
//  - The app's heal path still produces a clean second launch.
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
        // Tear down must wipe any quarantined files left behind by the
        // tests so the container does not accumulate stale
        // filters.json.corrupt-* files run after run.
        cleanupQuarantineFiles()
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

    private func cleanupQuarantineFiles() {
        for url in quarantineFiles() {
            try? FileManager.default.removeItem(at: url)
        }
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

        XCTAssertTrue(quarantineFiles().isEmpty,
                      "fetch(policy: .preserve) created a quarantine sidecar; preserve policy must be strictly read-only")
    }

    // MARK: - S1: corrupt bytes preserved in a quarantine sidecar

    /// The heal that the app runs on its first launch must move the bad
    /// bytes to a sidecar file before overwriting filters.json with an
    /// empty payload, so a partially-recoverable file can still be
    /// salvaged. The quarantine file lives in the same group container
    /// (the shared location for both the app and the extension) and is
    /// named filters.json.corrupt-<timestamp>.
    func test_AppHealQuarantinesCorruptBytesBeforeOverwrite() throws {
        guard let url = FilterStoreFile.fileURL else {
            XCTFail("filter store URL unavailable in test environment")
            return
        }

        let garbage = Data("{ \"phrase\": broken json, no closing brace".utf8)
        try garbage.write(to: url)

        _ = awaitPublisher(filterStore.fetch())

        let quarantine = quarantineFiles()
        XCTAssertEqual(quarantine.count, 1,
                       "Expected exactly one quarantine file after heal; got \(quarantine.count)")

        let onDisk = try Data(contentsOf: url)
        XCTAssertNoThrow(try JSONDecoder().decode([Filter].self, from: onDisk),
                         "filters.json was not healed into a parseable empty payload")

        let quarantinedBytes = try Data(contentsOf: quarantine[0])
        XCTAssertEqual(quarantinedBytes, garbage,
                       "Quarantine file does not contain the original corrupt bytes")
        XCTAssertTrue(quarantine[0].lastPathComponent.hasPrefix("filters.json.corrupt-"),
                      "Quarantine file name does not match filters.json.corrupt-<timestamp>")
    }

    // MARK: - App heal still works end-to-end

    /// App heal contract: after the heal, a fresh store sees the freshly
    /// written empty payload and returns success. This pins the behaviour
    /// the user-visible alert relies on: the alert fires once, on the
    /// first launch, and is silent on subsequent launches.
    func test_AppHealLeavesSecondLaunchClean() throws {
        guard let url = FilterStoreFile.fileURL else {
            XCTFail("filter store URL unavailable in test environment")
            return
        }
        try Data("garbage".utf8).write(to: url)

        // First launch: error path runs, file is healed (and quarantined).
        let first = awaitPublisher(filterStore.fetch())
        if case .failure(let error)? = first {
            switch error {
            case .loadError:
                break
            default:
                XCTFail("First launch on corrupt file must surface .loadError so the UI can show the alert; got \(error)")
            }
        } else {
            XCTFail("First launch on a corrupt file returned success; the alert path is supposed to fire on launch #1")
        }

        // The on-disk bytes must now be a parseable empty filter list.
        let onDisk = try Data(contentsOf: url)
        XCTAssertNoThrow(try JSONDecoder().decode([Filter].self, from: onDisk),
                         "filters.json was not healed into a parseable payload after first launch")

        // Second launch: a fresh store sees the now-valid file and returns
        // success without surfacing an error to the UI.
        let secondStore = FilterStoreFile()
        let second = awaitPublisher(secondStore.fetch())
        switch second {
        case .success(let filters):
            XCTAssertTrue(filters.isEmpty,
                          "Healed store should surface an empty rule list, not the user's old rules")
        case .failure(let error):
            XCTFail("Second launch after healing must not surface .loadError; got \(error)")
        case .none:
            XCTFail("Second launch publisher did not resolve")
        }
    }
}