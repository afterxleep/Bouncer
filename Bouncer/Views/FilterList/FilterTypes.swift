//
//  FilterTypes.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/20/20.
//

import Foundation
import SwiftUI

struct SystemImage: Hashable {
    var image: String
    var color: Color
}

struct FilterDestinationDecoration {
    var decoration: SystemImage
    var text: LocalizedStringKey
}

extension FilterType {
    var listDescription: SystemImage {
        switch self {
        case .any:
            return SYSTEM_IMAGES.ENTIRE_MESSAGE
        case .sender:
            return SYSTEM_IMAGES.SENDER
        case .message:
            return SYSTEM_IMAGES.MESSAGE_TEXT
        }
    }
    
    var formDescription: FilterDestinationDecoration {
        switch self {
        case .any:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.ENTIRE_MESSAGE, text: "ANYTHING_IN_MESSAGE")
        case .sender:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.SENDER, text: "SENDER_NUMBER")
        case .message:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.MESSAGE_TEXT, text: "TEXT")
        }
    }
}

extension FilterDestination {
    var listDescription: FilterDestinationDecoration {
        switch self {
        case .transactionOrder:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.TRANSACTION_ORDERS, text: "TRANSACTION_ACTION_ORDERS")
        case .transactionFinance:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.TRANSACTION_FINANCE, text: "TRANSACTION_ACTION_FINANCE")
        case .transactionReminders:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.TRANSACTION_REMINDERS, text: "TRANSACTION_ACTION_REMINDERS")
        case .promotionOffers:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.PROMOTION_OFFERS, text: "PROMOTION_ACTION_OFFERS")
        case .promotionCoupons:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.PROMOTION_COUPONS, text: "PROMOTION_ACTION_COUPONS")
        case .transactionOther:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.TRANSACTION, text: "TRANSACTION_ACTION")
        case .promotionOther:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.PROMOTION, text: "PROMOTION_ACTION")
        case .allow:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.ALLOW, text: "SAFE_ACTION")
        default:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.SPAM, text: "JUNK_ACTION")
        }
        
    }
}
