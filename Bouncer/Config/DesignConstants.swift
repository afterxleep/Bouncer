//
//  Constants.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/19/20.
//  Copyright © 2020 Daniel Bernal. All rights reserved.
//

import SwiftUI

enum DESIGN {
    
    enum TEXT {
        enum DARK {
            static let DEFAULT_COLOR = Color(red: 1, green: 1, blue: 1)
            static let HG_COLOR = Color(red: 0.63, green: 0.66, blue: 0.71)
        }
    }
    
    enum BUTTON {
        static let CORNER_RADIUS = CGFloat(25)
        enum DARK {
            static let BG_COLOR = Color(red: 0.294, green: 0.357, blue: 0.455)
            static let TEXT_COLOR = Color(red: 1, green: 1, blue: 1)
        }
    }
    
    enum UI {
        enum DARK {
            static let MAIN_BG_COLOR = Color(red: 0.004, green: 0.004, blue: 0.004)
            static let ACCENT_COLOR = Color(red: 0.63, green: 0.66, blue: 0.71)
        }
    }
    
    enum NAVIGATIONBAR {
        enum DARK {
            static let TITLE_COLOR =  UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            static let BACKGROUND_COLOR = UIColor(red: 0.23, green: 0.27, blue: 0.32, alpha: 1)
            
        }
    }
}

