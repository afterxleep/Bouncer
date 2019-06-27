//
//  WordListDummyService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class WordListDummyService: WordListService {
    
    let filteredWords: [String]
    
    init(wordList: [String]?) {
        self.filteredWords = wordList ?? ["123", "abaco", "comprar", "credito", "rappi", "tilde"]
    }
    
    func read() -> [String] {
        return filteredWords
    }
    
    func save(wordList: [String]) {
    }
    
}
