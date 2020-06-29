//
//  WordListDummyService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class FilterDummyStore {
    
    var filters: [Filter] = [
        Filter(id: UUID(), type: .any, phrase: "rappi", exactMatch: false),
        Filter(id: UUID(), type: .message, phrase: "uber", exactMatch: false),
        Filter(id: UUID(), type: .sender, phrase: "domicilio", exactMatch: true),
        Filter(id: UUID(), type: .any, phrase: "rappi", exactMatch: true),
    ]
    
    func save() {
    }
    
    func add(filter: Filter) {
        filters.append(filter)
    }
    
}
