//
//  FilterStoreCorruptRecoveryTests.swift
//  BouncerTests
//
//  An unreadable rules file must be reported without destroying its bytes.
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

    /// The caller needs an error so the UI can report the unreadable file.
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

    /// The original bytes may be recoverable, so a failed read cannot reset them.
    func test_UnreadableFileIsNotReplacedByEmptyRules() throws {
        let original = Data("garbage".utf8)
        let url = try XCTUnwrap(FilterStoreFile.fileURL)
        try original.write(to: url)

        _ = awaitPublisher(filterStore.fetch())

        XCTAssertEqual(try Data(contentsOf: url), original)
        let second = awaitPublisher(FilterStoreFile().fetch())
        if case .failure(.loadError)? = second {
            // Keep reporting the problem until the original data is recovered.
        } else {
            XCTFail("An unreadable store must not be silently replaced")
        }
    }
}
