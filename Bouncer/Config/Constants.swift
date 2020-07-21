//
//  Constants.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/19/20.
//  Copyright © 2020 Daniel Bernal. All rights reserved.
//

import SwiftUI

enum APP_STORAGE_KEYS: String {
    case HAS_LAUNCHED_APP
    case NUMBER_OF_LAUNCHES
    case LAST_VERSION_PROMPTED_FOR_REVIEW
}


enum DESIGN {
    enum BUTTON {
        static let CORNER_RADIUS = CGFloat(25)
    }
}

struct SYSTEM_IMAGES {
    static let ENTIRE_MESSAGE = SystemImage(image: "message", color: Color.green)
    static let SENDER = SystemImage(image: "person", color: Color.blue)
    static let MESSAGE_TEXT = SystemImage(image: "text.quote", color: Color.pink)
    static let SPAM = SystemImage(image: "bin.xmark", color: Color.red)
    static let TRANSACTION = SystemImage(image: "arrow.right.arrow.left", color: Color.blue)
    static let PROMOTION = SystemImage(image: "arrow.right.arrow.left", color: Color.green)
    static let HELP = SystemImage(image: "questionmark.circle", color: Color.white)
    static let ADD = SystemImage(image: "plus.circle", color: Color.white)
    static let CLOSE = SystemImage(image: "multiply.circle", color: Color("AccentColor"))
}


