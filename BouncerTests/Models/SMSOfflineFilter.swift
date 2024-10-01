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

    func testV1Filters() {
        var smsFilter: SMSOfflineFilter
        var filterResult: SMSOfflineFilterResponse
        
        let message = SMSMessage(sender: "ETB Comunicaciones", text: "ETB compra 100 megas y recibe 200 por 6 meses. Incluye extensor de velocidAd mas promocion especial. Llama ya sin costo al 018000413807. Ver TyC. Hasta 31 ago 2020")
        
        // Old style filters (Text + Regex)
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "etb", type: .any, action: .junk)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)

        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "comunica", type: .sender, action: .transaction)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .transaction)

        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "mega", type: .message, action: .promotion)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .promotion)
        
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "[a-z]cidad", type: .message, action: .junk, useRegex: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)

        // Content filter test
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "velocidad", type: .message, action: .junk, useRegex: false)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // Content filter test
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "VeLoCiDad", type: .message, action: .junk, useRegex: false, caseSensitive: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .none)

    }


    func testRegexFilter() {
        var smsFilter: SMSOfflineFilter
        var filterResult: SMSOfflineFilterResponse
        
        var message = SMSMessage(sender: "ETB Comunicaciones", text: "ETB compra 100 megas y recibe 200 por 6 meses. Incluye extensor de velocidAd mas promocion especial. Llama ya sin costo al 018000413807. Ver TyC. Hasta 31 ago 2020")
        
        // Regex filter test
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "[E].*[l][o]cidad", type: .message, action: .junk, useRegex: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // Regex filter test (Case sensitive)
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "[E].*[l][o]CidAd", type: .message, action: .junk, useRegex: true, caseSensitive: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .none)
        
        // Regex filter test (Case sensitive)
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "[E].*[l][o]cidAd", type: .message, action: .junk, useRegex: true, caseSensitive: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // Regex filter test (Case sensitive)
        // Match any string that contains any words “compra,” “extensor,” and “nuevo” in any order and at any position
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "compra|algo|nuevo", type: .message, action: .junk, useRegex: true, caseSensitive: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // Match any string that contains any words “compra,” “extensor,” and “nuevo” in any order and at any position
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "compra|extensor|nuevo", type: .message, action: .junk, useRegex: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // Match any string that contains all words “compra,” “meses,” and “megas” in any order and at any position
        // All Are included
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "(?=.*especial)(?=.*meses)(?=.*megas).*", type: .message, action: .junk, useRegex: true)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .junk)
        
        // Match any string that contains all words “compra,” “casa,” and “megas” in any order and at any position
        // Word casa is not included
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "(?=.*compra)(?=.*casa)(?=.*megas).*", type: .message, action: .junk, useRegex: true)])
        filterResult = smsFilter.filterMessage(message: message)
        print(filterResult.action)
        XCTAssertEqual(filterResult.action, .none)
        
        message = SMSMessage(sender: "Trump", text: """
        Shocked you didn't sign..will you PLEASE sign to STRIP Trump of immunity by passing the No Kings Act! SIGN: go.freedom-dems.org/0930a3
        
        Freedom Dems
        
        Stop2End
        """)
        
        // Match any word starting with 'dem' or 'Dem' in the message
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(), phrase: "\\bdem\\w+", type: .message, action: .junk, useRegex: true)])
        filterResult = smsFilter.filterMessage(message: message)
        print(filterResult.action)
        XCTAssertEqual(filterResult.action, .junk)
        
    }

    func testSubactionFilters() {
        var smsFilter: SMSOfflineFilter
        var filterResult: SMSOfflineFilterResponse

        var message = SMSMessage(sender: "ETB Comunicaciones", text: "ETB compra 100 megas y recibe 200 por 6 meses. Incluye extensor de velocidAd mas promocion especial. Llama ya sin costo al 018000413807. Ver TyC. Hasta 31 ago 2020")
        
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

        message = SMSMessage(sender: "+16205261342", text: "ULANKA:  Get 50% in shoes starting today!")
        
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(),
                                                         phrase: "ULANKA",
                                                         type: .any,
                                                         action: .promotion,
                                                         subAction: .promotionOffers)])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .promotion)
        XCTAssertEqual(filterResult.subaction, .promotionalOffers)
    }

    func testWhilelistFilters() {
        var smsFilter: SMSOfflineFilter
        var filterResult: SMSOfflineFilterResponse
        
        let message = SMSMessage(sender: "ETB Comunicaciones", text: "ETB compra 100 megas y recibe 200 por 6 meses. Incluye extensor de velocidAd mas promocion especial. Llama ya sin costo al 018000413807. Ver TyC. Hasta 31 ago 2020")
        
        // Allow list filter tests
        smsFilter = SMSOfflineFilter(filterList: [Filter(id: UUID(),
                                                         phrase: "etb",
                                                         type: .any,
                                                         action: .allow,
                                                         subAction: .none),
                                                  Filter(id: UUID(),
                                                         phrase: "etb",
                                                         type: .any,
                                                         action: .junk,
                                                         subAction: .none)
        ])
        filterResult = smsFilter.filterMessage(message: message)
        XCTAssertEqual(filterResult.action, .allow)
        XCTAssertEqual(filterResult.subaction, .none)
    }

}
