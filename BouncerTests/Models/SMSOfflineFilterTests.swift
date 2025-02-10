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
            (.transactionHealth, .transactionalOthers),
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
        
        // Test very long message
        let longText = String(repeating: "a", count: 10000)
        let message3 = SMSMessage(sender: "Service", text: longText)
        filter = SMSOfflineFilter(filterList: [
            Filter(id: UUID(), phrase: "a{9999}", type: .message, action: FilterDestination.transaction, useRegex: true)
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
}
