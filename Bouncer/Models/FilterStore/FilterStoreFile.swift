//
//  WordListFileStorageService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import Combine

final class FilterStoreFile: FilterStore {
    
    var filters: [Filter] = []
    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"
    
    init() {
        let testFilter = Filter(id: UUID(), phrase: "test", type: .any, action: .promotion)
        let _ = self.add(filter: testFilter)
    }

    fileprivate var fileURL: URL? {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)?
            .appendingPathComponent(Self.filterListFile)
    }
    
    fileprivate func saveToDisk() {
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
        guard let url = fileURL else {
            return Fail(error: .loadError).eraseToAnyPublisher()
        }
        do {
            let data = try Data(contentsOf: url)
            filters = try JSONDecoder().decode([Filter].self, from: data)
        } catch {
            return Fail(error: .decodingError).eraseToAnyPublisher()
        }

        return Just(filters)
            .setFailureType(to: FilterStoreError.self)
            .eraseToAnyPublisher()
    }
    
    func add(filter: Filter) -> AnyPublisher<Void, FilterStoreError> {
        filters.append(filter)
        filters = filters.sorted(by: { $1.phrase > $0.phrase })
        saveToDisk()
        return Empty().eraseToAnyPublisher()
    }
    
    func remove(uuid: UUID) -> AnyPublisher<Void, FilterStoreError> {
        filters = filters.filter{$0.id != uuid}
        saveToDisk()
        return Empty().eraseToAnyPublisher()
    }
    
    func reset() -> AnyPublisher<Void, FilterStoreError> {
        filters = []
        saveToDisk()
        return Empty().eraseToAnyPublisher()
    }
    
    func migrateFromV1() -> AnyPublisher<Void, FilterStoreError> {
        let wordListFile = "wordlist.filter"
        let storePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)
        let oldStore = storePath!.appendingPathComponent(wordListFile)
        if (FileManager.default.fileExists(atPath: oldStore.path)) {
            guard let wordData = NSMutableData(contentsOf: oldStore) else {
                return Fail(error: .loadError).eraseToAnyPublisher()
            }
            do {
                if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(wordData as Data) as? [String] {
                    for s in loadedStrings {
                        let _ = self.add(filter: Filter(id: UUID(), phrase: s))
                    }
                    try? FileManager.default.removeItem(atPath: oldStore.path)
                }
            } catch {
                return Fail(error: .migrationError).eraseToAnyPublisher()
            }
        }
        return Empty().eraseToAnyPublisher()
    }
}
