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
    static let ALERT_COLOR = Color("AlertColor")
    static let WARNING_COLOR = Color("WarningColor")
    static let OK_COLOR = Color("OkColor")
    static let DEFAULT_COLOR = Color("DefaultColor")
    static let DEFAULT_ICON_COLOR = Color("DefaultIconColor")
    static let ACCENT_COLOR = Color("AccentColor")

}


struct SYSTEM_IMAGES {
    static let ENTIRE_MESSAGE = SystemImage(image: "message", color: COLORS.DEFAULT_ICON_COLOR)
    static let SENDER = SystemImage(image: "person", color: COLORS.DEFAULT_ICON_COLOR)
    static let MESSAGE_TEXT = SystemImage(image: "text.quote", color: COLORS.DEFAULT_ICON_COLOR)
    static let SPAM = SystemImage(image: "bin.xmark", color: COLORS.ALERT_COLOR)
    static let TRANSACTION = SystemImage(image: "ellipsis.circle", color: COLORS.OK_COLOR)
    static let TRANSACTION_ORDERS = SystemImage(image: "shippingbox", color: COLORS.OK_COLOR)
    static let TRANSACTION_FINANCE = SystemImage(image: "creditcard", color: COLORS.OK_COLOR)
    static let TRANSACTION_REMINDERS = SystemImage(image: "calendar.badge.clock", color: COLORS.OK_COLOR)
    static let PROMOTION = SystemImage(image: "ellipsis.circle", color: COLORS.WARNING_COLOR)
    static let PROMOTION_OFFERS = SystemImage(image: "tag", color: COLORS.WARNING_COLOR)
    static let PROMOTION_COUPONS = SystemImage(image: "wallet.pass", color: COLORS.WARNING_COLOR)
    static let HELP = SystemImage(image: "questionmark.circle", color: COLORS.DEFAULT_COLOR)
    static let ADD = SystemImage(image: "plus.circle", color: COLORS.DEFAULT_COLOR)
    static let CLOSE = SystemImage(image: "multiply.circle", color: COLORS.ACCENT_COLOR)
    static let IMPORT_EXPORT_MENU = SystemImage(image: "ellipsis.circle", color: COLORS.ACCENT_COLOR)
    static let IMPORT = SystemImage(image: "square.and.arrow.down", color: COLORS.ACCENT_COLOR)
    static let EXPORT = SystemImage(image: "square.and.arrow.up", color: COLORS.ACCENT_COLOR)
    static let ROW_CHECKED = SystemImage(image: "checkmark.circle.fill", color: COLORS.OK_COLOR)
    static let ROW_UNCHECKED = SystemImage(image: "circle", color: COLORS.ACCENT_COLOR)
    static let WARNING = SystemImage(image: "exclamationmark.triangle", color: COLORS.WARNING_COLOR)
    static let CHECKLIST_OPTIONS = SystemImage(image: "checklist", color: COLORS.DEFAULT_COLOR)
    static let SELECT_ALL = SystemImage(image: "checklist.checked", color: COLORS.DEFAULT_COLOR)
    static let SELECT_NEW = SystemImage(image: "checklist", color: COLORS.DEFAULT_COLOR)
    static let SELECT_NONE = SystemImage(image: "checklist.unchecked", color: COLORS.DEFAULT_COLOR)
    static let SUPPORT = SystemImage(image: "support", color: COLORS.DEFAULT_COLOR)
}


