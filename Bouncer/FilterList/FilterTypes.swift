//
//  FilterTypes.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/20/20.
//

import Foundation
import SwiftUI

struct SystemImage {
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
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.ENTIRE_MESSAGE, text: "SENDER_AND_TEXT")
        case .sender:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.SENDER, text: "SENDER")
        case .message:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.MESSAGE_TEXT, text: "TEXT")
        }
    }
}

extension FilterDestination {
    var listDescription: FilterDestinationDecoration {
        switch self {
        case .junk:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.SPAM, text: "JUNK_ACTION")
        case .transaction:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.TRANSACTION, text: "TRANSACTION_ACTION")
        case .promotion:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.PROMOTION, text: "PROMOTION_ACTION")
        }
    }
    
    var formDescription: FilterDestinationDecoration {
        switch self {
        case .junk:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.SPAM, text: "JUNK_ACTION")
        case .transaction:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.TRANSACTION, text: "TRANSACTION_ACTION")
        case .promotion:
            return FilterDestinationDecoration(decoration: SYSTEM_IMAGES.PROMOTION, text: "PROMOTION_ACTION")
        }
    }
}
