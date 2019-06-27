//
//  UIColor+hexString.swift
//  Bouncer
//
//  Created by Daniel Bernal on 4/6/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit

extension UIColor{
    convenience init(hex: UInt, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}


