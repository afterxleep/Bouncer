//
//  FilterStoreCorruptRecoveryTests.swift
//  BouncerTests
//
//  Regression for the QA finding that a corrupt filters.json on disk is
//  never healed, so the "Bouncer couldn't read your rules" alert returns on
//  every launch and the only escape is reinstall. The contract the user
//  actually wants is: the first launch surfaces the error and the user is
//  told, but the file is overwritten with a fresh empty payload so the next
//  launch reaches a working app. The alert already explains that the rules
//  could not be read; reaching a clean state without reinstalling is the
//  priority.
//

import XCTest
import Combine
@testable import Bouncer

final class FilterStoreCorruptRecoveryTests: XCTestCase {

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

    /// First launch on a corrupt file still surfaces the failure to the
    /// caller (the UI shows the "couldn't read your rules" alert — that
    /// behaviour is the intended first-launch UX). The thing that was
    /// missing was the side effect of healing the file so the second launch
    /// does not get the same result.
    func test_CorruptFileFirstLaunchStillReportsError() throws {
        try Data("garbage".utf8).write(to: FilterStoreFile.fileURL!)

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
    }

    /// The bug QA reproduced: every subsequent launch kept seeing the same
    /// corrupt file and re-showed the alert. After the fix the first launch
    /// must overwrite the bad bytes with a fresh, parseable payload, so the
    /// second launch returns success (no alert).
    func test_CorruptFileSecondLaunchIsClean() throws {
        try Data("garbage".utf8).write(to: FilterStoreFile.fileURL!)

        // First launch: error path runs, file is healed.
        _ = awaitPublisher(filterStore.fetch())

        // The on-disk bytes must now be a parseable empty filter list.
        let onDisk = try Data(contentsOf: FilterStoreFile.fileURL!)
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