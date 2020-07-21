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

struct FilterActionDecoration {
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
    
    var formDescription: FilterActionDecoration {
        switch self {
        case .any:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.ENTIRE_MESSAGE, text: "SENDER_AND_TEXT")
        case .sender:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.SENDER, text: "SENDER")
        case .message:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.MESSAGE_TEXT, text: "TEXT")
        }
    }
}

extension FilterAction {
    var listDescription: FilterActionDecoration {
        switch self {
        case .junk:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.SPAM, text: "JUNK_ACTION")
        case .transaction:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.TRANSACTION, text: "TRANSACTION_ACTION")
        case .promotion:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.PROMOTION, text: "PROMOTION_ACTION")
        }
    }
    
    var formDescription: FilterActionDecoration {
        switch self {
        case .junk:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.SPAM, text: "JUNK_ACTION")
        case .transaction:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.TRANSACTION, text: "TRANSACTION_ACTION")
        case .promotion:
            return FilterActionDecoration(decoration: SYSTEM_IMAGES.PROMOTION, text: "PROMOTION_ACTION")
        }
    }
}
