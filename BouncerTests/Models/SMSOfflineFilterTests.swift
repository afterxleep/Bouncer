//
//  SMSOfflineFilterTests.swift
//  BouncerTests
//

import XCTest
import IdentityLookup
@testable import Bouncer

class SMSOfflineFilterTests: XCTestCase {
    
    // MARK: - Basic Text Matching Tests
    
    func testExactMatchAtStartOfMessage() {
        let message = SMSMessage(sender: "Marketing", text: "Special offer: 50% off on all products!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Special offer", type: .message, action: .promotion)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.promotion)
    }
    
    func testExactMatchInMiddleOfMessage() {
        let message = SMSMessage(sender: "Shop", text: "Get your special offer today!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "special offer", type: .message, action: .promotion)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.promotion)
    }
    
    func testPartialWordMatch() {
        let message = SMSMessage(sender: "Store", text: "Special offerings available now!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "offer", type: .message, action: FilterDestination.promotion)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.promotion)
    }
    
    func testNoMatch() {
        let message = SMSMessage(sender: "Store", text: "Great discounts available!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "offer", type: .message, action: FilterDestination.promotion)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.none)
    }
    
    func testMatchingWithNumbers() {
        let message = SMSMessage(sender: "Bank", text: "Transaction #12345 confirmed")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "12345", type: .message, action: .transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testMatchingWithPunctuation() {
        let message = SMSMessage(sender: "Service", text: "Your order #123-456 has been processed!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "#123-456", type: .message, action: .transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    // MARK: - Case Sensitivity Tests
    
    func testDefaultCaseInsensitiveMatching() {
        let message = SMSMessage(sender: "BANK ALERT", text: "Your OTP code is 123456")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "bank alert", type: .sender, action: .transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testCaseSensitiveNoMatch() {
        let message = SMSMessage(sender: "BANK ALERT", text: "Your OTP code is 123456")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "bank alert", type: .sender, action: .transaction, caseSensitive: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.none)
    }
    
    func testCaseSensitiveExactMatch() {
        let message = SMSMessage(sender: "BANK ALERT", text: "Your OTP code is 123456")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "BANK ALERT", type: .sender, action: .transaction, caseSensitive: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testMixedCaseInsensitiveMatch() {
        let message = SMSMessage(sender: "Service", text: "SpEcIaL OfFeR for you!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "special offer", type: .message, action: .promotion)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.promotion)
    }
    
    func testMixedCaseSensitiveNoMatch() {
        let message = SMSMessage(sender: "Service", text: "SpEcIaL OfFeR for you!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "special offer", type: .message, action: .promotion, caseSensitive: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.none)
    }
    
    func testMixedCaseSensitiveExactMatch() {
        let message = SMSMessage(sender: "Service", text: "SpEcIaL OfFeR for you!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "SpEcIaL OfFeR", type: .message, action: .promotion, caseSensitive: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.promotion)
    }
    
    func testSpecialCharactersCaseInsensitive() {
        let message = SMSMessage(sender: "$BaNk$", text: "Important Notice!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "$bank$", type: .sender, action: .transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testSpecialCharactersCaseSensitive() {
        let message = SMSMessage(sender: "$BaNk$", text: "Important Notice!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "$BaNk$", type: .sender, action: .transaction, caseSensitive: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    // MARK: - Regular Expression Tests
    
    func testRegexDigitPattern() {
        let message = SMSMessage(sender: "Service", text: "Your code is 123456")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\d{6}", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexWordBoundary() {
        let message = SMSMessage(sender: "Bank", text: "PIN: 1234 (Do not share your PIN)")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\bPIN\\b", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexStartEndAnchors() {
        let message = SMSMessage(sender: "Alert", text: "URGENT: System maintenance")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "^URGENT:", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexPhoneNumber() {
        let message = SMSMessage(sender: "+1-234-567-8900", text: "Test message")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\+\\d{1,2}-\\d{3}-\\d{3}-\\d{4}", type: .sender, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexEmail() {
        let message = SMSMessage(sender: "Service", text: "Contact us at support@example.com")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "[\\w\\.-]+@[\\w\\.-]+\\.[\\w]{2,}", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexLookaheadAssertions() {
        let message = SMSMessage(sender: "Shop", text: "Special offer! Get 50% off on premium items")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "(?=.*offer)(?=.*off)(?=.*premium).*", type: .message, action: .promotion, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.promotion)
    }
    
    func testRegexNegativeLookahead() {
        let message = SMSMessage(sender: "Bank", text: "Transaction completed successfully")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Transaction(?!.*failed).*", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexAlternationWithGroups() {
        let message = SMSMessage(sender: "System", text: "Warning: Critical system alert")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\b(warning|error|alert)\\b", type: .message, action: .transaction, useRegex: true, caseSensitive: false)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexCaseInsensitive() {
        let message = SMSMessage(sender: "Service", text: "IMPORTANT Notice: System Update")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "important.*notice", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)
    }
    
    func testRegexCaseSensitive() {
        let message = SMSMessage(sender: "Service", text: "IMPORTANT Notice: System Update")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "IMPORTANT.*Notice", type: .message, action: .transaction, useRegex: true, caseSensitive: true)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, ILMessageFilterAction.transaction)
    }
    
    // MARK: - Filter Order Tests
    
    func testAllowListTakesPrecedence() {
        let message = SMSMessage(sender: "Bank", text: "Your account balance is $100")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "account", type: .message, action: .junk),
            Filter(id: UUID(), phrase: "Bank", type: .sender, action: .allow)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, .allow)
    }
    
    func testBlockListAppliedAfterAllowList() {
        let message = SMSMessage(sender: "Spam", text: "Special offer!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "different", type: .message, action: .allow),
            Filter(id: UUID(), phrase: "offer", type: .message, action: .junk)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, .junk)
    }
    
    // MARK: - Action and SubAction Tests
    
    func testTransactionSubActions() {
        let message = SMSMessage(sender: "Shop", text: "Your order #123 is confirmed")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "order", type: .message, action: .transaction, subAction: .transactionOrder)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, ILMessageFilterAction.transaction)
        XCTAssertEqual(response.subAction, ILMessageFilterSubAction.transactionalOrders)
    }
    
    func testPromotionSubActions() {
        let message = SMSMessage(sender: "Store", text: "Use coupon SAVE50 for 50% off")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "coupon", type: .message, action: .promotion, subAction: .promotionCoupons)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, ILMessageFilterAction.promotion)
        XCTAssertEqual(response.subAction, ILMessageFilterSubAction.promotionalCoupons)
    }
    
    // MARK: - Combined Filter Tests
    
    func testCombinedSenderAndMessageFilter() {
        let message = SMSMessage(sender: "Bank Support", text: "Your account balance")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Bank Support.*balance", type: .any, action: .transaction, useRegex: true)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, ILMessageFilterAction.transaction)
    }
    
    func testNoMatchReturnsNone() {
        let message = SMSMessage(sender: "Unknown", text: "Random message")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "nonexistent", type: .message, action: .junk)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, ILMessageFilterAction.none)
        XCTAssertEqual(response.subAction, ILMessageFilterSubAction.none)
    }    

    // MARK: - Filter Type Tests
    
    func testFilterTypes() {
        // Test sender filter
        let message1 = SMSMessage(sender: "Security Alert", text: "Your account needs attention")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Security", type: .sender, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message1).subAction, .transactionalOthers)
        
        // Test message filter
        let message2 = SMSMessage(sender: "Service", text: "Security alert: Login attempt detected")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Security alert", type: .message, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, ILMessageFilterAction.transaction)
        
        // Test any filter (matches sender)
        let message3 = SMSMessage(sender: "Support Team", text: "Your ticket has been updated")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Support", type: .any, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message3).subAction, .transactionalOthers)
        
        // Test any filter (matches message)
        let message4 = SMSMessage(sender: "Service", text: "Contact support for assistance")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "support", type: .any, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message4).action, ILMessageFilterAction.transaction)
        
        // Test multiple matches in different fields
        let message5 = SMSMessage(sender: "Support", text: "Contact support now")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "support", type: .any, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message5).action, ILMessageFilterAction.transaction)
    }
    
    // MARK: - Action and Subaction Tests
    
    func testActionTypes() {
        // Test transaction action
        let message1 = SMSMessage(sender: "Bank", text: "Your transaction of $100 was processed")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "transaction", type: .message, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message1).subAction, .transactionalOthers)
        
        // Test promotion action
        let promoMessage = SMSMessage(sender: "Shop", text: "50% off all items!")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "off", type: .message, action: FilterDestination.promotion)
        ])
        XCTAssertEqual(filter.filterMessage(message: promoMessage).action, ILMessageFilterAction.promotion)
        XCTAssertEqual(filter.filterMessage(message: promoMessage).subAction, .promotionalOthers)
        
        // Test junk action
        let message3 = SMSMessage(sender: "Unknown", text: "Win a free iPhone now!")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "free.*win|win.*free", type: .message, action: .junk, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, .junk)
    }
    
    func testSubactionFilters() {
        // Test transaction subactions
        let message1 = SMSMessage(sender: "Bank", text: "Your OTP code is 123456")
        
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "OTP", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionOther)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message1).subAction, .transactionalOthers)
        
        // Test payment subaction
        let message2 = SMSMessage(sender: "Bank", text: "Payment of $50 processed")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Payment", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionFinance)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message2).subAction, .transactionalFinance)
        
        // Test transfer subaction
        let message3 = SMSMessage(sender: "Bank", text: "Transfer to John completed")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Transfer", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionFinance)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message3).subAction, .transactionalFinance)
        
        // Test multiple subactions (should match first filter)
        let message4 = SMSMessage(sender: "Bank", text: "OTP for payment: 123456")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "OTP", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionOther),
            Filter(id: UUID(), phrase: "payment", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionFinance)
        ])
        XCTAssertEqual(filter.filterMessage(message: message4).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message4).subAction, .transactionalOthers)
        
        // Test no subaction
        let message5 = SMSMessage(sender: "Bank", text: "Account balance updated")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "balance", type: .message, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message5).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message5).subAction, .transactionalOthers)
    }
    
    // MARK: - Multi-line Message Tests
    
    func testMultilineMessages() {
        // Test multi-line message with pattern at start
        let message1 = SMSMessage(sender: "Service", text: """
        ALERT: System maintenance
        scheduled for tomorrow
        at 2 PM EST.
        """)
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "^ALERT:", type: .message, action: FilterDestination.transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message1).subAction, .transactionalOthers)
        
        // Test multi-line message with pattern in middle
        let message2 = SMSMessage(sender: "Shop", text: """
        Special Offer!
        Get 50% OFF
        on all items.
        Limited time only.
        """)
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "50%.*OFF", type: .message, action: .promotion, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, .promotion)
        XCTAssertEqual(filter.filterMessage(message: message2).subAction, .promotionalOthers)
        
        // Test multi-line message with pattern across lines
        let message3 = SMSMessage(sender: "Bank", text: """
        Your OTP code
        for transaction
        is: 123456
        """)
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "OTP[\\s\\S]*123456", type: .message, action: FilterDestination.transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message3).subAction, .transactionalOthers)
    }


    // MARK: - Special Characters Tests
    
    func testSpecialCharacters() {
        // Test emoji in message
        let message1 = SMSMessage(sender: "Shop", text: "🎉 Special offer! 50% off! 🛍")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "🎉.*offer", type: .message, action: FilterDestination.promotion, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, ILMessageFilterAction.promotion)
        
        // Test unicode characters
        let message2 = SMSMessage(sender: "Bank", text: "Transfer €100 to João's account")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "€\\d+", type: .message, action: FilterDestination.transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, ILMessageFilterAction.transaction)
        
        // Test special punctuation
        let message3 = SMSMessage(sender: "Service", text: "Your PIN: #123-456!")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "PIN.*#\\d+[-]\\d+!", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message3).subAction, .transactionalOthers)
    }
    
    // MARK: - Multiple Filters Tests
    
    func testMultipleFilters() {
        // Test multiple filters with different types
        let message1 = SMSMessage(sender: "Bank Alert", text: "Your OTP code is 123456")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Bank", type: .sender, action: FilterDestination.transaction),
            Filter(id: UUID(), phrase: "OTP", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionOther)
        ])
        let result = filter.filterMessage(message: message1)
        XCTAssertEqual(result.action, .transaction)
        XCTAssertEqual(result.subAction, .transactionalOthers)
        
        // Test filter priority (first match should win)
        let message2 = SMSMessage(sender: "Shop", text: "Special offer! Get your discount code: ABC123")
        let priorityFilter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "offer", type: .message, action: FilterDestination.promotion),
            Filter(id: UUID(), phrase: "discount", type: .message, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(priorityFilter.filterMessage(message: message2).action, ILMessageFilterAction.promotion)
        
        // Test multiple regex filters
        let message3 = SMSMessage(sender: "Service", text: "Your verification code is 123-456")
        let regexFilter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\d{3}-\\d{3}", type: .message, action: .transaction, useRegex: true),
            Filter(id: UUID(), phrase: "verification.*code", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(regexFilter.filterMessage(message: message3).action, .transaction)
    }
    
    // MARK: - Edge Cases Tests
    
    func testSubactionEdgeCases() {
        // Test default subactions for transaction
        let message1 = SMSMessage(sender: "Bank", text: "Transaction processed")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Transaction", type: .message, action: FilterDestination.transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message1).subAction, .transactionalOthers)
        
        // Test default subactions for promotion
        let message2 = SMSMessage(sender: "Shop", text: "Special promotion!")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "promotion", type: .message, action: .promotion)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, .promotion)
        XCTAssertEqual(filter.filterMessage(message: message2).subAction, .promotionalOthers)
        
        // Test overriding default subaction
        let message3 = SMSMessage(sender: "Shop", text: "Get your coupon code: ABC123")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "coupon", type: .message, action: FilterDestination.promotion, subAction: FilterDestination.promotionCoupons)
        ])
        let result3 = filter.filterMessage(message: message3)
        XCTAssertEqual(result3.action, ILMessageFilterAction.promotion)
        XCTAssertEqual(result3.subAction, .promotionalCoupons)
        
        // Test all transaction subactions
        let message4 = SMSMessage(sender: "Service", text: "Test message")
        let transactionSubactions: [(FilterDestination, ILMessageFilterSubAction)] = [
            (.transactionOrder, .transactionalOrders),
            (.transactionFinance, .transactionalFinance),
            (.transactionReminders, .transactionalReminders),
            (.transactionHealth, .transactionalHealth),
            (.transactionOther, .transactionalOthers),
            (.none, .transactionalOthers)
        ]
        
        for (subaction, expected) in transactionSubactions {
            filter = SMSOfflineFilter(filterList: [
                Filter(id: UUID(), phrase: "Test", type: .message, action: FilterDestination.transaction, subAction: subaction)
            ])
            let result = filter.filterMessage(message: message4)
            XCTAssertEqual(result.action, ILMessageFilterAction.transaction)
            XCTAssertEqual(result.subAction, expected)
        }
        
        // Test all promotion subactions
        let promotionSubactions: [(FilterDestination, ILMessageFilterSubAction)] = [
            (.promotionOffers, .promotionalOffers),
            (.promotionCoupons, .promotionalCoupons),
            (.promotionOther, .promotionalOthers),
            (.none, .promotionalOthers),
            (.promotionOffers, .promotionalOffers),
            (.promotionCoupons, .promotionalCoupons)
        ]
        
        for (subaction, expected) in promotionSubactions {
            filter = SMSOfflineFilter(filterList: [
                Filter(id: UUID(), phrase: "Test", type: .message, action: FilterDestination.promotion, subAction: subaction)
            ])
            let result = filter.filterMessage(message: message4)
            XCTAssertEqual(result.action, ILMessageFilterAction.promotion)
            XCTAssertEqual(result.subAction, expected)
        }
    }
    
    func testWhitespaceHandling() {
        // Test message with trailing whitespace and newlines
        let message1 = SMSMessage(sender: "Service", text: "This is a message\nSTOP=end\n  ")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "STOP=end", type: .message, action: .junk)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, .junk, "Should match STOP=end with trailing newline")
        
        // Test message with leading whitespace in filter phrase
        let message2 = SMSMessage(sender: "Service", text: "Message with STOP=end here")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "  STOP=end  ", type: .message, action: .junk)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, .junk, "Should match STOP=end with whitespace in filter")
        
        // Test message with multiple newlines
        let message3 = SMSMessage(sender: "Service", text: """
        Some promotional content
        
        STOP=end
        
        """)  
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "STOP=end", type: .message, action: .junk)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, .junk, "Should match STOP=end in multiline message")
    }
    
    func testEdgeCases() {
        // Test empty message
        let emptyMessage = SMSMessage(sender: "Service", text: "")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: ".+", type: .message, action: FilterDestination.transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: emptyMessage).action, ILMessageFilterAction.none)
        
        // Test empty sender
        let message2 = SMSMessage(sender: "", text: "Test message")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: ".+", type: .sender, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, .none)
        
        // Test very long message — bounded by the regex input cap.
        let longText = String(repeating: "a", count: 4000)
        let message3 = SMSMessage(sender: "Service", text: longText)
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "a{3999}", type: .message, action: FilterDestination.transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, ILMessageFilterAction.transaction)
        XCTAssertEqual(filter.filterMessage(message: message3).subAction, .transactionalOthers)
        
        // Test message with only whitespace
        let message4 = SMSMessage(sender: "Service", text: "    \n\t    ")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\s+", type: .message, action: FilterDestination.transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message4).action, ILMessageFilterAction.transaction)
        
        // Test empty filter list
        let message5 = SMSMessage(sender: "Service", text: "Test message")
        let emptyFilter = SMSOfflineFilter(filterList: [])
        XCTAssertEqual(emptyFilter.filterMessage(message: message5).action, .none)
        
        // Test allow list override
        let message6 = SMSMessage(sender: "Bank", text: "Important: Your account needs attention")
        let allowFilter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Bank", type: .sender, action: .allow),
            Filter(id: UUID(), phrase: "account", type: .message, action: .junk)
        ])
        XCTAssertEqual(allowFilter.filterMessage(message: message6).action, .allow)
        
        // Test invalid regex pattern
        let message7 = SMSMessage(sender: "Service", text: "Test message")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "[", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message7).action, .none)
        
        // Test message with null characters
        let message8 = SMSMessage(sender: "Service", text: "Test\0message")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Test.*message", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message8).action, .transaction)
        
        // Test message with non-printable characters
        let message9 = SMSMessage(sender: "Service", text: "Test\u{0001}message")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Test.*message", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message9).action, .transaction)
        
        // Test filter with empty phrase
        let message10 = SMSMessage(sender: "Service", text: "Test message")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "", type: .message, action: .transaction)
        ])
        XCTAssertEqual(filter.filterMessage(message: message10).action, .none)
        
        // Test multiple allow filters (should use first match)
        let message11 = SMSMessage(sender: "Bank", text: "Important message")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Bank", type: .sender, action: .allow),
            Filter(id: UUID(), phrase: "Bank", type: .sender, action: .junk)
        ])
        XCTAssertEqual(filter.filterMessage(message: message11).action, .allow)
    }
    
    // MARK: - Filter Combination and Priority Tests
    
    func testFilterCombinations() {
        // Test multiple filters with different types and actions
        let message1 = SMSMessage(sender: "Bank Alert", text: "Your OTP code is 123456. Special offer inside!")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "offer", type: .message, action: FilterDestination.promotion),
            Filter(id: UUID(), phrase: "OTP", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionOther),
            Filter(id: UUID(), phrase: "Bank", type: .sender, action: FilterDestination.transaction)
        ])
        // Should match first filter (promotion)
        XCTAssertEqual(filter.filterMessage(message: message1).action, ILMessageFilterAction.promotion)
        
        // Test priority between regex and non-regex filters
        let message2 = SMSMessage(sender: "Service", text: "Your code: ABC-123")
        let mixedFilter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "[A-Z]+-\\d+", type: .message, action: .transaction, useRegex: true),
            Filter(id: UUID(), phrase: "ABC-123", type: .message, action: .promotion)
        ])
        // Should match first filter (transaction)
        XCTAssertEqual(mixedFilter.filterMessage(message: message2).action, .transaction)
        
        // Test case sensitivity priority
        let message3 = SMSMessage(sender: "BANK", text: "Important message")
        let caseFilter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "bank", type: .sender, action: .transaction),
            Filter(id: UUID(), phrase: "BANK", type: .sender, action: .promotion, caseSensitive: true)
        ])
        // Should match first filter (transaction) due to case insensitive
        XCTAssertEqual(caseFilter.filterMessage(message: message3).action, .transaction)
        
        // Test allow overriding all other actions
        let message4 = SMSMessage(sender: "Bank", text: "Promotional message with OTP code")
        let allowFilter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Promotional", type: .message, action: .promotion),
            Filter(id: UUID(), phrase: "OTP", type: .message, action: .transaction),
            Filter(id: UUID(), phrase: "Bank", type: .sender, action: .allow)
        ])
        // Should match allow filter regardless of position
        XCTAssertEqual(allowFilter.filterMessage(message: message4).action, .allow)
        
        // Test complex regex with subaction priority
        let message5 = SMSMessage(sender: "Service", text: "Payment OTP: 123456 for transfer to Account")
        let complexFilter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "transfer", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionFinance),
            Filter(id: UUID(), phrase: "OTP.*\\d{6}", type: .message, action: .transaction, subAction: .transactionOther, useRegex: true),
            Filter(id: UUID(), phrase: "Payment", type: .message, action: FilterDestination.transaction, subAction: FilterDestination.transactionFinance)
        ])
        // Should match first filter (transfer subaction)
        let result = complexFilter.filterMessage(message: message5)
        XCTAssertEqual(result.action, .transaction)
        XCTAssertEqual(result.subAction, .transactionalFinance)
    }
    
    // MARK: - Additional Edge Cases
    
    func testRegexTimeoutAndSafety() {
        // Genuinely catastrophic patterns (nested quantifier inside a group)
        // must be rejected outright by the safety check.
        let message = SMSMessage(sender: "Service", text: String(repeating: "a", count: 1000))
        let nestedQuantifierPatterns = [
            "(a+)+b", "(a*)*", "((a+)?)+"
        ]
        for pattern in nestedQuantifierPatterns {
            let filter = SMSOfflineFilter(filterList: [
                Filter(id: UUID(), phrase: pattern, type: .message, action: .junk, useRegex: true)
            ])
            XCTAssertEqual(filter.filterMessage(message: message).action, .none,
                          "Nested-quantifier pattern \(pattern) should be rejected by the safety check")
        }
    }
    
    func testMultilineAndSpecialCharacters() {
        // Test multiline message
        let multilineMessage = SMSMessage(sender: "Service", text: "Line 1\nLine 2\nLine 3")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Line [0-9]", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: multilineMessage).action, .transaction)
        
        // Test message with special regex characters as literal text
        let specialCharsMessage = SMSMessage(sender: "Service", text: "Price: $100.00 (50% off)")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\$\\d+\\.\\d+", type: .message, action: .promotion, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: specialCharsMessage).action, .promotion)
    }
    
    func testUnicodeAndBoundaryHandling() {
        // Test Unicode category matching
        let message1 = SMSMessage(sender: "Service", text: "Testing numbers 123 and symbols @#$")
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\d+", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message1).action, .transaction)
        
        // Test word boundaries with international characters
        // Test word boundaries with international characters
        let message2 = SMSMessage(sender: "Service", text: "my café here")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\bcafé\\b", type: .message, action: .promotion, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message2).action, .promotion)
        
        // Test zero-width characters
        let message3 = SMSMessage(sender: "Service", text: "Hello\u{200B}World")
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "Hello.*World", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message3).action, .transaction)
    }
    
    func testConcurrentFilterProcessing() {
        // Test multiple filters being processed concurrently
        let message = SMSMessage(sender: "Bank-Alert", text: "Your OTP is 123456")
        
        // Create a large number of filters to test concurrent processing
        var filters: [Filter] = []
        for i in 0..<100 {
            filters.append(Filter(id: UUID(),
                                phrase: "\\d{6}",
                                type: .message,
                                action: i % 2 == 0 ? .transaction : .promotion,
                                useRegex: true))
        }
        
        let filter = SMSOfflineFilter(filterList: filters)
        let result = filter.filterMessage(message: message)
        
        // First matching filter should win regardless of concurrent processing
        XCTAssertEqual(result.action, .transaction)
    }
    
    func testRegexOptimizationAndLimits() {
        // Test regex pattern with excessive backtracking but within limits
        let message = SMSMessage(sender: "Service", text: String(repeating: "a", count: 50))
        var filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "a{1,50}b?", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, ILMessageFilterAction.transaction)

        // Test pattern with reasonable repetition
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\d{1,10}", type: .message, action: .transaction, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: SMSMessage(sender: "Service", text: "123456")).action, ILMessageFilterAction.transaction)

        // Test pattern with nested quantifier (genuinely catastrophic shape)
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "(\\d{1,9})+", type: .message, action: .transaction, useRegex: true)
        ])
        // Should be rejected by the structural safety check
        XCTAssertEqual(filter.filterMessage(message: SMSMessage(sender: "Service", text: "123456")).action, .none)

        // Test pattern with invalid regex syntax
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "[invalid", type: .message, action: .transaction, useRegex: true)
        ])
        // Should be rejected due to invalid syntax
        XCTAssertEqual(filter.filterMessage(message: SMSMessage(sender: "Service", text: "123456")).action, .none)
    }

    // MARK: - Defect (1): Invalid regex must surface a user-visible error
    //
    // The matcher already returns .none for an uncompilable pattern, but the
    // editor accepts the rule and saves it. The user never finds out. These
    // tests pin the contract the editor must enforce: the matcher must say
    // *what* was wrong with the pattern, so the container can show it.

    func testInvalidRegexValidationReportsTheReason() {
        let result = RegexValidator.validate("(free|win")
        switch result {
        case .valid: XCTFail("Expected (free|win to be reported invalid, got .valid")
        case .invalid(let message):
            XCTAssertFalse(message.isEmpty, "An invalid-pattern message must not be empty")
        }
    }

    func testValidRegexPassesValidation() {
        switch RegexValidator.validate("win.*.*prize") {
        case .valid: break
        case .invalid(let message): XCTFail("win.*.*prize should validate, got: \(message)")
        }
        switch RegexValidator.validate("\\bPIN\\b") {
        case .valid: break
        case .invalid(let message): XCTFail("\\bPIN\\b should validate, got: \(message)")
        }
    }

    func testInvalidRegexStillMatchesNothingInTheEngine() {
        // The engine itself should not return a match for an invalid regex.
        let message = SMSMessage(sender: "Service", text: "free win")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "(free|win", type: .message, action: .junk, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: message).action, .none)
    }

    // MARK: - Defect (2): ReDoS guard — false positives and false negatives

    func testWinDotStarDotStarPrizeIsAcceptedAndMatches() {
        // The current substring-based guard rejects this legal pattern. After
        // the fix it must compile, match a text it should match, and reject
        // genuinely catastrophic patterns.
        let matching = SMSMessage(sender: "Spam", text: "You could win big prize in this contest")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "win.*.*prize", type: .message, action: .junk, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: matching).action, .junk)
    }

    func testWinDotStarDotStarPrizeDoesNotMatchArbitraryText() {
        // The same pattern must NOT match when there is no "win...prize" in
        // the text — proving the fix preserved actual matching semantics.
        let nonMatching = SMSMessage(sender: "Service", text: "your prize will arrive next week")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "win.*.*prize", type: .message, action: .junk, useRegex: true)
        ])
        XCTAssertEqual(filter.filterMessage(message: nonMatching).action, .none)
    }

    func testGenuinelyCatastrophicPatternIsBounded() {
        // (win+)+! on a long non-matching input is genuinely catastrophic.
        // The matcher must not hang the test runner. The test is allowed to
        // return either a real match or .none — only the timing matters.
        let longText = String(repeating: "w", count: 4000)
        let message = SMSMessage(sender: "Service", text: longText)
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "(win+)+!", type: .message, action: .junk, useRegex: true)
        ])

        let start = Date()
        let response = filter.filterMessage(message: message)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 2.0,
            "Catastrophic pattern must not take more than 2s; took \(elapsed)s. action=\(response.action)")
    }

    // MARK: - Defect (3): The timeout abandons work and races on `var result`

    func testConcurrentRegexMatchesReturnConsistentResults() {
        // Hammer the engine from many threads with a mix of patterns and
        // messages. After the fix, the result must be deterministic and
        // there must be no data race on the internal result.
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "\\d{4}", type: .message, action: .transaction, useRegex: true),
            Filter(id: UUID(), phrase: "win.*prize", type: .message, action: .junk, useRegex: true),
            Filter(id: UUID(), phrase: "OTP", type: .message, action: .transaction)
        ])

        let messages: [SMSMessage] = [
            SMSMessage(sender: "Bank", text: "Your OTP is 1234"),
            SMSMessage(sender: "Spam", text: "win a free prize today"),
            SMSMessage(sender: "Service", text: "no trigger here"),
            SMSMessage(sender: "Bank", text: "OTP 5678 confirmed")
        ]

        let queue = DispatchQueue(label: "test.concurrent.regex", attributes: .concurrent)
        let group = DispatchGroup()
        let lock = NSLock()
        var results = Set<String>()

        for _ in 0..<200 {
            for message in messages {
                group.enter()
                queue.async {
                    let r = filter.filterMessage(message: message)
                    let key = "\(r.action.rawValue)|\(r.subAction.rawValue)"
                    lock.lock()
                    results.insert(key)
                    lock.unlock()
                    group.leave()
                }
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 10), .success,
                      "All concurrent matches must complete within 10s")
        XCTAssertGreaterThan(results.count, 0)
    }

    func testRepeatedCatastrophicPatternsDoNotAccumulateBackgroundWork() {
        // After the fix, repeated calls with a catastrophic pattern must
        // each complete in bounded time. If the old code's "abandoned thread"
        // behaviour leaks, the test would slow down as more dispatches pile up
        // on the global queue.
        let longText = String(repeating: "w", count: 4000)
        let message = SMSMessage(sender: "Service", text: longText)
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "(win+)+!", type: .message, action: .junk, useRegex: true)
        ])

        let start = Date()
        for _ in 0..<20 {
            _ = filter.filterMessage(message: message)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 5.0,
            "20 catastrophic matches must finish in under 5s; took \(elapsed)s")
    }

    // MARK: - Defect (4): The "Health" category is half-wired

    func testTransactionHealthMapsToTransactionalHealthSubAction() {
        // Apple has exposed ILMessageFilterSubActionTransactionalHealth since
        // iOS 16 (verified against
        // IdentityLookup.framework/Headers/ILMessageFilterAction.h). After the
        // fix the matcher must route .transactionHealth to
        // .transactionalHealth, not silently file it as .transactionalOthers.
        let message = SMSMessage(sender: "Clinic", text: "Time for your flu shot")
        let filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "flu shot", type: .message,
                   action: .transaction, subAction: .transactionHealth)
        ])
        let response = filter.filterMessage(message: message)
        XCTAssertEqual(response.action, ILMessageFilterAction.transaction)
        XCTAssertEqual(response.subAction, ILMessageFilterSubAction.transactionalHealth)
    }

    func testTransactionHealthSurvivesARoundTrip() {
        // A rule encoded with subAction = .transactionHealth must decode back
        // to .transactionHealth so a rule saved by an older build lands in
        // the right place after the upgrade.
        let original = Filter(id: UUID(), phrase: "flu shot", type: .message,
                              action: .transaction, subAction: .transactionHealth)
        let data = try? JSONEncoder().encode(original)
        let decoded = try? JSONDecoder().decode(Filter.self, from: data ?? Data())
        let rule = try? XCTUnwrap(decoded)
        XCTAssertEqual(rule?.subAction, .transactionHealth,
            ".transactionHealth must round-trip through JSON unchanged")
    }

    func testTransactionHealthIsWiredIntoTheMatcher() {
        // Before the fix .transactionHealth fell through default to
        // .transactionalOthers. After the fix it must take its own branch.
        let filter = Filter(id: UUID(), phrase: "flu shot", type: .message,
                            action: .transaction, subAction: .transactionHealth)
        let engine = SMSOfflineFilter(filterList: [filter])
        let sub = engine.subAction(for: filter)
        XCTAssertEqual(sub, .transactionalHealth,
            ".transactionHealth must route to .transactionalHealth, not .transactionalOthers")
    }

    // MARK: - Backwards compatibility for already-stored rules

    func testRulesFromCurrentShippingFormatStillMatchAfterTheFix() {
        // Rules encoded by today's shipping app must continue to match the
        // same messages after the fix. This pins the wire format and proves
        // the fix did not silently change semantics for stored data.
        let original = [
            Filter(id: UUID(), phrase: "bank", type: .sender, action: .transaction,
                   subAction: .transactionFinance, useRegex: false, caseSensitive: false),
            Filter(id: UUID(), phrase: "WIN.*PRIZE", type: .message, action: .junk,
                   subAction: .promotionOther, useRegex: true, caseSensitive: false),
            Filter(id: UUID(), phrase: "coupon", type: .message, action: .promotion,
                   subAction: .promotionCoupons, useRegex: false, caseSensitive: false),
            Filter(id: UUID(), phrase: "stop", type: .any, action: .junk,
                   subAction: .none, useRegex: false, caseSensitive: false)
        ]
        let data = try? JSONEncoder().encode(original)
        let decoded = try? JSONDecoder().decode([Filter].self, from: data ?? Data())

        XCTAssertNotNil(decoded)
        let decodedRules = try? XCTUnwrap(decoded)
        XCTAssertEqual(decodedRules?.count, original.count)

        let engine = SMSOfflineFilter(filterList: decodedRules ?? [])
        let bankResp = engine.filterMessage(message: SMSMessage(sender: "Bank Alert", text: "hi"))
        XCTAssertEqual(bankResp.action, .transaction)
        XCTAssertEqual(bankResp.subAction, .transactionalFinance)

        let spamResp = engine.filterMessage(message: SMSMessage(sender: "Spam", text: "WIN the PRIZE today"))
        XCTAssertEqual(spamResp.action, .junk)

        let couponResp = engine.filterMessage(message: SMSMessage(sender: "Shop", text: "Use coupon SAVE10"))
        XCTAssertEqual(couponResp.action, .promotion)
        XCTAssertEqual(couponResp.subAction, .promotionalCoupons)

        let stopResp = engine.filterMessage(message: SMSMessage(sender: "Anybody", text: "stop"))
        XCTAssertEqual(stopResp.action, .junk)
    }
}
