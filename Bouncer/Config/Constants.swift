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
    static let OK_COLOR = Color("OKColor")
    static let DEFAULT_COLOR = Color("DefaultColor")
    static let DEFAULT_ICON_COLOR = Color("DefaultIconColor")
    static let ACCENT_COLOR = Color("AccentColor")

}


struct SYSTEM_IMAGES {
    static let ENTIRE_MESSAGE = SystemImage(image: "message", color: COLORS.DEFAULT_ICON_COLOR)
    static let SENDER = SystemImage(image: "person", color: COLORS.DEFAULT_ICON_COLOR)
    static let MESSAGE_TEXT = SystemImage(image: "text.quote", color: COLORS.DEFAULT_ICON_COLOR)
    static let SPAM = SystemImage(image: "bin.xmark", color: COLORS.ALERT_COLOR)
    static let TRANSACTION = SystemImage(image: "arrow.left.arrow.right", color: COLORS.OK_COLOR)
    static let PROMOTION = SystemImage(image: "tag", color: COLORS.WARNING_COLOR)
    static let HELP = SystemImage(image: "questionmark.circle", color: COLORS.DEFAULT_COLOR)
    static let ADD = SystemImage(image: "plus.circle", color: COLORS.DEFAULT_COLOR)
    static let CLOSE = SystemImage(image: "multiply.circle", color: COLORS.ACCENT_COLOR)
}


