//
//  Constants.swift
//  Bouncer
//

import SwiftUI

enum DESIGN {
    enum BUTTON {
        static let CORNER_RADIUS = CGFloat(25)
    }
}

struct COLORS {
    static let ALERT_COLOR = Color("Thunderbird")
    static let OK_COLOR = Color("DeepForest")
    static let DEFAULT_COLOR = Color("DefaultColor")
    static let DEFAULT_ICON_COLOR = Color("DefaultIconColor")
    static let ACCENT_COLOR = Color("AccentColor")
    static let PALLETE_1 = Color("Underblue")
    static let PALLETE_2 = Color("SteelBlue")
    static let PALLETE_3 = Color("Victoria")
    static let PALLETE_4 = Color("Jakarta")
    static let PALLETE_5 = Color("Rosebud")
    static let PALLETE_6 = Color("Trinidad")
    static let PALLETE_7 = Color("Pizazz")
}


struct SYSTEM_IMAGES {
    static let ENTIRE_MESSAGE = SystemImage(image: "message", color: COLORS.DEFAULT_ICON_COLOR)
    static let SENDER = SystemImage(image: "person", color: COLORS.DEFAULT_ICON_COLOR)
    static let MESSAGE_TEXT = SystemImage(image: "text.quote", color: COLORS.DEFAULT_ICON_COLOR)
    static let SPAM = SystemImage(image: "bin.xmark", color: COLORS.ALERT_COLOR)
    static let TRANSACTION = SystemImage(image: "ellipsis.circle", color: COLORS.PALLETE_1)
    static let TRANSACTION_ORDERS = SystemImage(image: "shippingbox", color: COLORS.PALLETE_1)
    static let TRANSACTION_FINANCE = SystemImage(image: "creditcard", color: COLORS.PALLETE_2)
    static let TRANSACTION_REMINDERS = SystemImage(image: "calendar.badge.clock", color: COLORS.PALLETE_3)
    static let PROMOTION = SystemImage(image: "ellipsis.circle", color: COLORS.PALLETE_4)
    static let PROMOTION_OFFERS = SystemImage(image: "tag", color: COLORS.PALLETE_4)
    static let PROMOTION_COUPONS = SystemImage(image: "wallet.pass", color: COLORS.PALLETE_5)
    static let HELP = SystemImage(image: "questionmark.circle", color: COLORS.DEFAULT_COLOR)
    static let ADD = SystemImage(image: "plus.circle", color: COLORS.DEFAULT_COLOR)
    static let CLOSE = SystemImage(image: "multiply.circle", color: COLORS.ACCENT_COLOR)
    static let IMPORT_EXPORT_MENU = SystemImage(image: "ellipsis.circle", color: COLORS.ACCENT_COLOR)
    static let IMPORT = SystemImage(image: "square.and.arrow.down", color: COLORS.ACCENT_COLOR)
    static let EXPORT = SystemImage(image: "square.and.arrow.up", color: COLORS.ACCENT_COLOR)
    static let ROW_CHECKED = SystemImage(image: "checkmark.circle.fill", color: COLORS.OK_COLOR)
    static let ROW_UNCHECKED = SystemImage(image: "circle", color: COLORS.ACCENT_COLOR)
    static let CHECKLIST_OPTIONS = SystemImage(image: "checklist", color: COLORS.DEFAULT_COLOR)
    static let SELECT_ALL = SystemImage(image: "checklist.checked", color: COLORS.DEFAULT_COLOR)
    static let SELECT_NEW = SystemImage(image: "checklist", color: COLORS.DEFAULT_COLOR)
    static let SELECT_NONE = SystemImage(image: "checklist.unchecked", color: COLORS.DEFAULT_COLOR)
    static let SUPPORT = SystemImage(image: "support", color: COLORS.DEFAULT_COLOR)
    static let ALLOW = SystemImage(image: "checkmark.circle", color: COLORS.DEFAULT_COLOR)
}


