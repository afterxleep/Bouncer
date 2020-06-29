//
//  WordListFileStorageService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import Combine

final class FilterFileStore: ObservableObject {
    
    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"
    
    @Published private(set) var filters: [Filter] = []
    
    init() {
        readFromDisk()
    }
        
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

    private var fileURL: URL? {
        do {
            let fileURL = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent(Self.filterListFile)
                return fileURL
        } catch {
            return nil
        }
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
