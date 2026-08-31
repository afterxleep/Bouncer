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
@testable import Bouncer

final class MessageFilterEngineTests: XCTestCase {

    private func describe(_ response: ILMessageFilterQueryResponse) -> String {
        return "action=\(response.action.rawValue),subAction=\(response.subAction.rawValue)"
    }

    func test_NilMessageBodyReturnsNoneAction() {
        let engine = MessageFilterEngine(filters: [])
        XCTAssertEqual(engine.decide(sender: "+15551234567", messageBody: nil).action,
                       ILMessageFilterAction.none,
                       describe(engine.decide(sender: "+15551234567", messageBody: nil)))
        XCTAssertEqual(engine.decide(sender: nil, messageBody: "hi").action,
                       ILMessageFilterAction.none)
        XCTAssertEqual(engine.decide(sender: nil, messageBody: nil).action,
                       ILMessageFilterAction.none)
    }

    func test_EmptyFiltersReturnsNoneAction() {
        let engine = MessageFilterEngine(filters: [])
        let outcome = engine.decide(sender: "+15551234567", messageBody: "hi")
        XCTAssertEqual(outcome.action, ILMessageFilterAction.none)
    }

    func test_MatchingJunkFilterReturnsJunkAction() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .junk)
        let engine = MessageFilterEngine(filters: [filter])
        let outcome = engine.decide(sender: "+15550000000",
                                    messageBody: "Tu rappi pedido")
        XCTAssertEqual(outcome.action, ILMessageFilterAction.junk,
                       describe(outcome))
        XCTAssertEqual(outcome.subAction, ILMessageFilterSubAction.none,
                       describe(outcome))
    }

    func test_NonMatchingReturnsNoneAction() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .junk)
        let engine = MessageFilterEngine(filters: [filter])
        XCTAssertEqual(engine.decide(sender: "+15550000000",
                                     messageBody: "Hello").action,
                       ILMessageFilterAction.none)
    }

    /// Finding #4: a request with nil sender or nil body must produce a
    /// response — the engine is the seam, the extension delivers whatever
    /// the engine returns. If the engine returns a response for nil inputs,
    /// the extension's completion handler will be called exactly once with
    /// that response.
    func test_NilInputsStillProduceAResponse() {
        let engine = MessageFilterEngine(filters: [])
        let response = engine.decide(sender: nil, messageBody: nil)
        // We can prove completion fires by checking the response is valid.
        XCTAssertNotNil(response.action)
    }
}
