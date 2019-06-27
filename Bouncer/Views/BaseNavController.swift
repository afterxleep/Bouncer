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
    let largeTitle = true
    let titleColor = UIColor.white
    let bgColor = UIColor.init(hex: 0x495C73, alpha: 1)
    
    //MARK: - Superview Inits
    
    override init(rootViewController : UIViewController) {
        super.init(rootViewController : rootViewController)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.navigationBar.isTranslucent = false
        self.navigationBar.tintColor = tintColor
        self.navigationBar.barTintColor = bgColor
        self.navigationBar.prefersLargeTitles = largeTitle
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        self.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass : navigationBarClass, toolbarClass : toolbarClass)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
    

