//
//  DesignSystem.swift
//  Bouncer
//
//  One place for the visual language: brand colour, spacing, radii and the
//  chip/badge treatments shared by the rule list, the rule form and import.
//

import SwiftUI

// MARK: - Palette

/// The brand palette. Every colour resolves from the asset catalogue so it has
/// a light and a dark variant of the *same* hue.
enum Brand {
    /// App tint — the blue from the Bouncer mark.
    static let tint = Color("AccentColor")

    // Category hues. Assigned for separation rather than by palette order:
    // neighbours in the destination picker sit far apart on the wheel, and the
    // two catch-all buckets take the neutral so the named ones own the colour.
    static let junk = Color("Thunderbird")          // red
    static let safe = Color("DeepForest")           // green
    static let orders = Color("SteelBlue")          // blue
    static let finance = Color("Victoria")          // indigo
    static let reminders = Color("Jakarta")         // violet
    static let offers = Color("Pizazz")             // amber
    static let coupons = Color("RoseBud")           // pink
    static let promotionOther = Color("Trinidad")   // coral
    static let transactionOther = Color("Underblue")// neutral slate
}

// MARK: - Metrics

/// Spacing, radii and sizes. Multiples of 4 so vertical rhythm stays even.
enum Metrics {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    /// Leading icon well in a rule row.
    static let rowIconSize: CGFloat = 34
    /// One radius per role: cards, badges, and capsules for controls.
    static let badgeRadius: CGFloat = 10
    static let cardRadius: CGFloat = 18
}

// MARK: - Category

/// A rule's destination, expressed for the UI: one symbol, one hue, one name.
/// This is the single source of truth — rows, pickers and the import preview
/// all read from here so a category can never drift between screens.
struct Category {
    let symbol: String
    let tint: Color
    /// Plain string keys, so a category name can be used both as a
    /// `LocalizedStringKey` in a view and as a resolved `String` inside a
    /// formatted sentence.
    let titleKey: String
    /// Short form for chips and other tight spaces, where a group heading
    /// already supplies the context ("Other" under "Transactions").
    let shortKey: String

    var title: LocalizedStringKey { LocalizedStringKey(titleKey) }
    var shortTitle: LocalizedStringKey { LocalizedStringKey(shortKey) }

    /// The resolved name, for use in formatted strings.
    var name: String { NSLocalizedString(titleKey, comment: "") }
}

extension FilterDestination {

    /// The category a rule belongs to, resolving sub-actions to their parent
    /// when a rule predates the sub-action model.
    var category: Category {
        switch self {
        case .allow:
            return Category(symbol: "checkmark.shield.fill", tint: Brand.safe, titleKey: "SAFE_ACTION", shortKey: "SAFE_ACTION")
        case .junk, .none:
            return Category(symbol: "hand.raised.fill", tint: Brand.junk, titleKey: "JUNK_ACTION", shortKey: "JUNK_ACTION")
        case .transactionOrder:
            return Category(symbol: "shippingbox.fill", tint: Brand.orders, titleKey: "TRANSACTION_ACTION_ORDERS", shortKey: "TRANSACTION_ACTION_ORDERS")
        case .transactionFinance:
            return Category(symbol: "creditcard.fill", tint: Brand.finance, titleKey: "TRANSACTION_ACTION_FINANCE", shortKey: "TRANSACTION_ACTION_FINANCE")
        case .transactionReminders:
            return Category(symbol: "calendar.badge.clock", tint: Brand.reminders, titleKey: "TRANSACTION_ACTION_REMINDERS", shortKey: "TRANSACTION_ACTION_REMINDERS")
        case .transaction, .transactionHealth, .transactionOther:
            return Category(symbol: "tray.full.fill", tint: Brand.transactionOther, titleKey: "TRANSACTION_ACTION", shortKey: "OTHER_SHORT")
        case .promotionOffers:
            return Category(symbol: "tag.fill", tint: Brand.offers, titleKey: "PROMOTION_ACTION_OFFERS", shortKey: "PROMOTION_ACTION_OFFERS")
        case .promotionCoupons:
            return Category(symbol: "wallet.pass.fill", tint: Brand.coupons, titleKey: "PROMOTION_ACTION_COUPONS", shortKey: "PROMOTION_ACTION_COUPONS")
        case .promotion, .promotionOther:
            return Category(symbol: "megaphone.fill", tint: Brand.promotionOther, titleKey: "PROMOTION_ACTION", shortKey: "OTHER_SHORT")
        }
    }
}

extension Filter {

    /// The category to show for this rule: the sub-action when it carries one,
    /// otherwise the base action.
    var category: Category {
        let destination = (subAction == .none) ? action : subAction
        return destination.category
    }

    /// The rule's phrase as the user wrote it — slashed when it's a regex.
    var displayPhrase: String {
        useRegex ? "/\(phrase)/" : phrase
    }
}

extension FilterType {

    var symbol: String {
        switch self {
        case .any: return "text.bubble"
        case .sender: return "person.crop.circle"
        case .message: return "text.quote"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .any: return "ANYTHING_IN_MESSAGE"
        case .sender: return "SENDER_NUMBER"
        case .message: return "TEXT"
        }
    }

    /// Short form used in a rule row, where space is tight.
    var shortTitle: LocalizedStringKey {
        switch self {
        case .any: return "SCOPE_SHORT_ANY"
        case .sender: return "SCOPE_SHORT_SENDER"
        case .message: return "SCOPE_SHORT_MESSAGE"
        }
    }
}

