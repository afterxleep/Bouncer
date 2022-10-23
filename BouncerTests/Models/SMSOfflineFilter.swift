//
//  SMSOfflineFilter.swift
//  BouncerTests
//

import XCTest
import IdentityLookup
@testable import Bouncer

class SMSOfflineFilterTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    func testFiltering() {
        var smsFilter: SMSOfflineFilter

        let message = SMSMessage(sender: "ETB Comunicaciones", text: "ETB compra 100 megas y recibe 200 por 6 meses. Incluye extensor de velocidad mas promocion especial. Llama ya sin costo al 018000413807. Ver TyC. Hasta 31 ago 2020")

        var filterResult: SMSOfflineFilterResponse
        
        // Old style filters (Text + Regex)
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "etb", type: .any, action: .junk)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)

        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "comunica", type: .sender, action: .promotion)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .transaction)

        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "mega", type: .message, action: .transaction)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .promotion)
        
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "[a-z]cidad", type: .message, action: .junk)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
                
        // Regex filter test
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "[E].*[l][o]cidad", type: .message, action: .junk, useRegex: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // Content filter test
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "velocidad", type: .message, action: .junk, useRegex: false)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // SubAction filter tests
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(),
                                                         phrase: "etb",
                                                         type: .any,
                                                         action: .transaction,
                                                         subAction: .transactionOrder)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .transaction)
        XCTAssertEqual(filterResult.subaction, .transactionalOrders)
        
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(),
                                                         phrase: "etb",
                                                         type: .any,
                                                         action: .transaction,
                                                         subAction: .transactionFinance)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .transaction)
        XCTAssertEqual(filterResult.subaction, .transactionalFinance)
        
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(),
                                                         phrase: "etb",
                                                         type: .any,
                                                         action: .transaction,
                                                         subAction: .transactionReminders)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .transaction)
        XCTAssertEqual(filterResult.subaction, .transactionalReminders)
        
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(),
                                                         phrase: "etb",
                                                         type: .any,
                                                         action: .promotion,
                                                         subAction: .promotionOffers)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .promotion)
        XCTAssertEqual(filterResult.subaction, .promotionalOffers)
        
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(),
                                                         phrase: "etb",
                                                         type: .any,
                                                         action: .promotion,
                                                         subAction: .promotionCoupons)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .promotion)
        XCTAssertEqual(filterResult.subaction, .promotionalCoupons)

    }
}
