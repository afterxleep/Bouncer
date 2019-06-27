//
//  DataSource.swift
//  Bouncer
//
//  Created by Miguel D Rojas Cortés on 3/13/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

protocol DataSource {
    func numberOfItems() -> Int
    func word(atIndex index: IndexPath) -> String?
    func removeWord(atIndex index: IndexPath) -> Bool
}
