//
//  StoryBoarded.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit

// Protocol to access Viewcontrollers directly from Storyboards

protocol Storyboarded {
    static func instatiate(fromStoryboard: String) -> Self
}

extension Storyboarded {
    
    static func instatiate(fromStoryboard: String) -> Self {
        
        let name = NSStringFromClass(self as! AnyClass)
        let className = name.components(separatedBy: ".")[1]
        let storyboard = UIStoryboard(name: fromStoryboard, bundle: Bundle.main)
        
        return storyboard.instantiateViewController(withIdentifier: className) as! Self
    }
    
}
