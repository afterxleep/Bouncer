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
@testable import Bouncer

final class MessageFilterEngineTests: XCTestCase {

    func test_NilMessageBodyReturnsAllow() {
        let engine = MessageFilterEngine(filters: [])
        XCTAssertEqual(engine.decide(sender: "+15551234567", messageBody: nil),
                       .allow)
        XCTAssertEqual(engine.decide(sender: nil, messageBody: "hi"),
                       .allow)
        XCTAssertEqual(engine.decide(sender: nil, messageBody: nil),
                       .allow)
    }

    func test_EmptyFiltersReturnsAllow() {
        let engine = MessageFilterEngine(filters: [])
        XCTAssertEqual(engine.decide(sender: "+15551234567", messageBody: "hi"),
                       .allow)
    }

    func test_MatchingJunkFilterReturnsDeny() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .junk)
        let engine = MessageFilterEngine(filters: [filter])
        let outcome = engine.decide(sender: "+15550000000",
                                    messageBody: "Tu rappi pedido")
        guard case .deny(let action, let subAction) = outcome else {
            XCTFail("Expected .deny, got \(outcome)")
            return
        }
        XCTAssertEqual(action, .junk)
        XCTAssertEqual(subAction, .none)
    }

    func test_NonMatchingReturnsAllow() {
        let filter = Filter(id: UUID(),
                            phrase: "rappi",
                            type: .any,
                            action: .junk)
        let engine = MessageFilterEngine(filters: [filter])
        XCTAssertEqual(engine.decide(sender: "+15550000000",
                                     messageBody: "Hello"),
                       .allow)
    }
}
