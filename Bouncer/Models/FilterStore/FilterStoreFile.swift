//
//  WordListFileStorageService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import Combine

final class FilterStoreFile: FilterStoreProtocol {
    
    var filters: [Filter] = []
    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"
    
    init() {
        let testFilter = Filter(id: UUID(), phrase: "test", type: .any, action: .promotion)
        self.add(filter: testFilter)
    }

    private var fileURL: URL? {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)?
            .appendingPathComponent(Self.filterListFile)
    }
    
    private func saveToDisk() {
        guard let url = fileURL else {
            filters = []
            return
        }
        do {
            try JSONEncoder().encode(filters)
                .write(to: url)
        } catch {
            print(error)
        }
    }
}


extension FilterStoreFile {
    
    func get() -> AnyPublisher<[Filter], FilterStoreError> {
        var filters: [Filter] = []
        guard let url = fileURL else {  // File does not exist yet
            return Fail(error: .loadError).eraseToAnyPublisher()
        }
        do {
            let data = try Data(contentsOf: url)
            filters = try JSONDecoder().decode([Filter].self, from: data)
        } catch {
            return Fail(error: .decodingError).eraseToAnyPublisher()
        }
        return Just(filters).setFailureType(to: FilterStoreError.self).eraseToAnyPublisher()
        
    }
    
    func add(filter: Filter) {
        filters.append(filter)
        filters = filters.sorted(by: { $1.phrase > $0.phrase })
        saveToDisk()
    }
    
    func remove(id: UUID) -> AnyPublisher<Void, FilterStoreError> {
        filters = filters.filter{$0.id != id}
        saveToDisk()
        return Just(()).setFailureType(to: FilterStoreError.self).eraseToAnyPublisher()
    }
    
    func reset() {
        filters = []
        saveToDisk()
    }
    
    func migrateFromV1() {
        let wordListFile = "wordlist.filter"
        let storePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)
        let oldStore = storePath!.appendingPathComponent(wordListFile)
        if (FileManager.default.fileExists(atPath: oldStore.path)) {
            guard let wordData = NSMutableData(contentsOf: oldStore) else { return }
            do {
                if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(wordData as Data) as? [String] {
                    for s in loadedStrings {
                        self.add(filter: Filter(id: UUID(), phrase: s))
                    }
                    try? FileManager.default.removeItem(atPath: oldStore.path)
                }
            } catch {
                return
            }
        }
    }
}
