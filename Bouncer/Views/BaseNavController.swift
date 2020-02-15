//
//  BaseNavController.swift
//  Bouncer
//
//  Created by Daniel Bernal on 4/6/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit
    
class BaseNavController : UINavigationController {
    
    //MARK: - Deisgn vars
    let tintColor = UIColor.white
    let titleColor = UIColor.white
    let accentColor = UIColor(named: "AccentColor")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // General Tint
        UINavigationBar.appearance().tintColor = tintColor
        UINavigationBar.appearance().prefersLargeTitles = true
        
        // General Appearance
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.backgroundColor = accentColor
        standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        standardAppearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().compactAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = standardAppearance

        

    }
}
    

