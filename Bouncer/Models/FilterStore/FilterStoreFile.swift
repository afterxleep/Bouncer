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
    
    @Published var filters: [Filter] = []
    var filtersPublisher: Published<[Filter]>.Publisher { $filters }
    
    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"
    
    init() {
        readFromDisk()
    }

    private var fileURL: URL? {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)?
            .appendingPathComponent(Self.filterListFile)
    }
    
    private func readFromDisk() {
        guard let url = fileURL else {  // File does not exist yet
            filters = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            filters = try JSONDecoder().decode([Filter].self, from: data)
        } catch {
            print(error)
        }
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
    
    func add(filter: Filter) {
        filters.append(filter)
        filters = filters.sorted(by: { $1.phrase > $0.phrase })
        saveToDisk()
    }
    
    func remove(id: UUID) {
        filters = filters.filter{$0.id != id}
        saveToDisk()
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
