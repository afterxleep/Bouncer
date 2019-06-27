//
//  WordListService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

protocol WordListService {
    func read() -> [String]
    func save(wordList: [String])    
}

extension WordListService {
    
    // Remove accents, lowercase, sort, unique
    func sanitize(words: [String]) -> [String] {
        return Array(Set(words.map({
            (word: String) -> String in
            return word.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        }))).sorted()
    }
    
}
