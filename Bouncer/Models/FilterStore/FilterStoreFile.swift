//
//  FilterStoreFile.swift
//  Bouncer
//

import Foundation
import Combine

final class FilterStoreFile: FilterStore {
    
    var filters: [Filter] = []
    var cancellables = [AnyCancellable]()
    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"

    fileprivate var fileURL: URL? {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)?
            .appendingPathComponent(Self.filterListFile)
    }
    
    fileprivate func saveToDisk(filters: [Filter]) {
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
        let wordListFile = "wordlist.filter"
        let storePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)
        let oldStore = storePath!.appendingPathComponent(wordListFile)
        if (FileManager.default.fileExists(atPath: oldStore.path)) {
            guard let wordData = NSMutableData(contentsOf: oldStore) else {
                print("Migration Failed")
                return
            }
            do {
                if let loadedStrings = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(wordData as Data) as? [String] {
                    for s in loadedStrings {
                        let _ = self.add(filter: Filter(id: UUID(), phrase: s))
                    }
                    try? FileManager.default.removeItem(atPath: oldStore.path)
                    print("Migration Complete or not required")
                }
            } catch {
                print("Migration Failed")
            }
        }
    }
}
