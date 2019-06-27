//
//  AppDelegate+MainInjection.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/26/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit
import Swinject

extension AppDelegate {

    func registerDependencies() {
        
        container = Container()
        
        // Main Coordinator
        container?.register(MainCoordinator.self) { resolver in
            let navController = BaseNavController(navigationBarClass: nil, toolbarClass: nil)
            let userDataService = resolver.resolve(UserDataService.self) ?? UserDataDefaultsService()
            return MainCoordinator(navigationController: navController, userDataService: userDataService)
        }
    }
    
}

