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
    let bgColor = UIColor.init(hex: 0x495C73, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // General Tint
        UINavigationBar.appearance().tintColor = tintColor
        
        // General Appearance
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.backgroundColor = bgColor
        standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        standardAppearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        UINavigationBar.appearance().standardAppearance = standardAppearance
        
    }
}
    

