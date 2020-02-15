//
//  Coordinator.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit

protocol Coordinator: class {
    
    var userDataService: UserDataService { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

