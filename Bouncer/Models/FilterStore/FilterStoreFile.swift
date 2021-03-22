//
//  FilterStoreFile.swift
//  Bouncer
//

import Foundation
import Combine

final class FilterStoreFile: FilterStore {
    
    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"
    static let filterListFileV1 = "wordlist.filter"
    
    var filters: [Filter] = []
    var cancellables = [AnyCancellable]()
    
    private var fileURL: URL? {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)?
            .appendingPathComponent(Self.filterListFile)
    }
    
    private func fileExists(url: URL) -> Bool {
        guard let url = self.fileURL else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func saveToDisk(filters: [Filter]) {
        guard let url = fileURL else {
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
    
    func fetch() -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { promise in
            var filters: [Filter] = []
            guard let url = self.fileURL else {
                promise(.failure(.loadError))
                return
            }
            // Create the filter store if it does not exist
            if(!self.fileExists(url: url)) {
                let filters = [Filter]()
                self.saveToDisk(filters: filters)
                promise(.success(filters))
            }
            do {
                let data = try Data(contentsOf: url)
                filters = try JSONDecoder().decode([Filter].self, from: data)
                promise(.success(filters))
            } catch {
                
                promise(.failure(.decodingError))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func add(filter: Filter) -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { promise in
            self.fetch()
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                    var filters: [Filter] = result
                    filters.append(filter)
                    filters = filters.sorted(by: { $1.phrase > $0.phrase })
                    self?.saveToDisk(filters: filters)
                    promise(.success(()))
                })
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    func update(filter: Filter) -> AnyPublisher<Void, Never> {
        return Future<Void, Never> { promise in
            self.fetch()
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                    var filters = result
                    
                    if let filterIndex = result.firstIndex(where: { $0.id == filter.id }) {
                        filters[filterIndex] = filter
                        self?.saveToDisk(filters: filters)
                        promise(.success(()))
                    }
                })
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    func remove(uuid: UUID) -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { promise in
            self.fetch()
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                    var filters: [Filter] = result
                    filters = filters.filter{$0.id != uuid}
                    self?.saveToDisk(filters: filters)
                    promise(.success(()))
                })
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    func reset() -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { promise in
            self.saveToDisk(filters: [])
            promise(.success(()))
        }.eraseToAnyPublisher()
    }
    
    func migrateFromV1() -> Void {
        let wordListFile = Self.filterListFileV1
        let storePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)
        let oldStore = storePath!.appendingPathComponent(wordListFile)
        if (FileManager.default.fileExists(atPath: oldStore.path)) {
            guard let wordData = NSMutableData(contentsOf: oldStore) else {                
                return
            }
            do {
                if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(wordData as Data) as? [String] {
                    for s in loadedStrings {
                        let _ = self.add(filter: Filter(id: UUID(), phrase: s))
                    }
                    try? FileManager.default.removeItem(atPath: oldStore.path)
                }
            } catch {
            }
        }
    }
}
