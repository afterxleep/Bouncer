//
//  WordListFileStorageService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class WordListFileStorageService: WordListService {
    
    
    static let wordListFile = "wordlist.filter"
    static let groupContainer = "group.com.banshai.bouncer"
    
    func storePath() -> URL? {
        let fileManager = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WordListFileStorageService.groupContainer)
        return fileManager?.appendingPathComponent(WordListFileStorageService.wordListFile)
    }
    
    func read() -> [String] {
        guard let storePath = storePath() else { return [] }
        guard let wordData = NSMutableData(contentsOf: storePath) else { return [] }
        
        do {
            if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(wordData as Data) as? [String] {
                return loadedStrings
            }
        } catch {
            return []
        }
        return []
    }
    
    func save(wordList: [String]) {
        guard let storePath = storePath() else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: sanitize(words: wordList), requiringSecureCoding: false)
            try data.write(to: storePath)
        } catch {
            print("Couldn't write data")
        }
    }
    
}
