//
//  WordListDummyService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class FilterStoreDummyService: FilterStoreService {
    
    var filters: [Filter] = [
        Filter(id: UUID(), type: .any, phrase: "rappi", exactMatch: false),
        Filter(id: UUID(), type: .message, phrase: "uber", exactMatch: false),
        Filter(id: UUID(), type: .sender, phrase: "other", exactMatch: true)
    ]
    
    func read() -> [Filter] {
        return filters
    }
    
    func save(filterList: [Filter]) {
    }
    
    func add(filter: Filter) {
        filters.append(filter)
    }
    
}
