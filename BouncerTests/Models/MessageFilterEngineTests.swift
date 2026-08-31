//
//  MessageFilterEngineTests.swift
//  BouncerTests
//
//  Finding #4 + #5: the extension's handle(_:context:completion:) must call
//  completion exactly once on every path, including nil messageBody and a
//  store failure, and the scheduler must not depend on the run loop mode.
//
//  We test the extracted engine (MessageFilterEngine.decide) which is what
//  MessageFilterExtension.handle delegates to. The handle method becomes a
//  thin fetch + completion wrapper; the engine is what decides what the
//  completion delivers. If decide produces an outcome for every input,
//  handle will call completion with the matching ILMessageFilterQueryResponse.
//

import XCTest
import IdentityLookup
import Combine
@testable import Bouncer

final class MessageFilterEngineTests: XCTestCase {

    private func describe(_ response: ILMessageFilterQueryResponse) -> String {
        return "action=\(response.action.rawValue),subAction=\(response.subAction.rawValue)"
    }

    func test_NilMessageBodyReturnsNoneAction() {
        let engine = MessageFilterEngine(filters: [])
        XCTAssertEqual(engine.decide(sender: "+15551234567", messageBody: nil).response.action,
                       ILMessageFilterAction.none,
                       describe(engine.decide(sender: "+15551234567", messageBody: nil).response))
        XCTAssertEqual(engine.decide(sender: nil, messageBody: "hi").response.action,
                       ILMessageFilterAction.none)
        XCTAssertEqual(engine.decide(sender: nil, messageBody: nil).response.action,
                       ILMessageFilterAction.none)
    }

    func test_EmptyFiltersReturnsNoneAction() {
        let engine = MessageFilterEngine(filters: [])
        let outcome = engine.decide(sender: "+15551234567", messageBody: "hi")
        XCTAssertEqual(outcome.response.action, ILMessageFilterAction.none)
    }

    func test_MatchingJunkFilterReturnsJunkAction() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .junk)
        let engine = MessageFilterEngine(filters: [filter])
        let outcome = engine.decide(sender: "+15550000000",
                                    messageBody: "Tu rappi pedido")
        XCTAssertEqual(outcome.response.action, ILMessageFilterAction.junk,
                       describe(outcome.response))
        XCTAssertEqual(outcome.response.subAction, ILMessageFilterSubAction.none,
                       describe(outcome.response))
    }

    func test_NonMatchingReturnsNoneAction() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .junk)
        let engine = MessageFilterEngine(filters: [filter])
        XCTAssertEqual(engine.decide(sender: "+15550000000",
                                     messageBody: "Hello").response.action,
                       ILMessageFilterAction.none)
    }

    /// A rule with `.none` action still matches messages — it is used to bucket
    /// or sort a message without filtering it. Activity recording must fire for
    /// it the same as for any other matching rule, so `decide` returns the
    /// matched `Filter` regardless of action. The previous gate in the
    /// extension (`response.action != .none`) silently suppressed activity for
    /// these rules.
    func test_NoneActionFilterStillReturnsMatchedFilter() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .none)
        let engine = MessageFilterEngine(filters: [filter])
        let outcome = engine.decide(sender: "+15550000000",
                                    messageBody: "Tu rappi pedido")
        XCTAssertNotNil(outcome.matched,
                        "a .none-action rule that matched must come back as the matched filter so activity is recorded")
        XCTAssertEqual(outcome.matched?.id, filter.id)
    }

    /// When nothing matches, decide returns a `.none` response and no matched
    /// filter — so activity is not recorded.
    func test_NonMatchingReturnsNilMatchedFilter() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .junk)
        let engine = MessageFilterEngine(filters: [filter])
        let outcome = engine.decide(sender: "+15550000000",
                                    messageBody: "Hello")
        XCTAssertNil(outcome.matched)
    }

    /// Finding #4 + #5 (extension wiring): when the store fetch fails,
    /// `filterStore.fetch()` resolves with `.failure`, the extension's
    /// receiveCompletion handler runs, and completion is delivered with an
    /// allow verdict. We prove the seam by simulating a failing fetch and
    /// observing that fetch() terminates (which is the precondition for the
    /// extension's receiveCompletion to run and call completion).
    func test_StoreFailurePathFetchResolvesWithFailure() throws {
        // Write garbage so the in-store decode fails — the same condition
        // that drives the extension's failure branch.
        try Data("not json".utf8).write(to: FilterStoreFile.fileURL!)
        let store = FilterStoreFile()
        let publisher = store.fetch()

        let expectation = self.expectation(description: "fetch resolves on corrupt store")
        var failureCount = 0
        var successCount = 0
        let cancellable = publisher.sink(receiveCompletion: { completion in
            if case .failure = completion { failureCount += 1 }
            expectation.fulfill()
        }, receiveValue: { _ in
            successCount += 1
            expectation.fulfill()
        })
        waitForExpectations(timeout: 2, handler: nil)
        _ = cancellable // keep alive until wait returns
        XCTAssertEqual(successCount, 0, "fetch must not deliver success on a corrupt store")
        XCTAssertEqual(failureCount, 1, "fetch must deliver .failure exactly once on a corrupt store")
    }
}
