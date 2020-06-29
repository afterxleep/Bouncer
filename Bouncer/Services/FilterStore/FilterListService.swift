//
//  WordListService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

protocol FilterService {
    func read() -> [Filter]
    func save(filterList: [Filter])
}

extension FilterService {
    
    // Remove accents, lowercase, sort, unique
    func sanitize(filters: [Filter]) -> [Filter] {
        return filters
        
        /*
        return Array(Set(words.map({
            (word: String) -> String in
            return word.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        }))).sorted()
         */
    }
    
}
