//
//  FilterStoreFile.swift
//  Bouncer
//

import Foundation
import Combine
import os.log

private typealias DiskWriteError = String

final class FilterStoreFile: FilterStore {
    
    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"
    static let filterListFileV1 = "wordlist.filter"
    
    var filters: [Filter] = []
    var cancellables = [AnyCancellable]()
    
    static var fileURL: URL? {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupContainer)?
            .appendingPathComponent(Self.filterListFile)
    }
    
    private var fileURL: URL? {
        return Self.fileURL
    }
    
    private func fileExists(url: URL) -> Bool {
        guard let url = self.fileURL else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func saveToDisk(filters: [Filter]) -> DiskWriteError? {
        guard let url = fileURL else {
            return nil
        }
        
        do {
            try JSONEncoder().encode(filters)
                .write(to: url)
            return nil
        } catch {
            let errorMessage = error.localizedDescription
            os_log("Error: %s.", type: .error, errorMessage)            
            return errorMessage
        }
    }

    private func decodeData(data: Data) -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { promise in

            // Decode with current version
            guard let filters = try? JSONDecoder().decode([Filter].self, from: data) else {

                // Try migrating the database if decoding fails
                // TODO: For future versions, a more robust store might be needed - CoreData?
                _ = self.migrateDatabase()
                    .sink(receiveCompletion: { _ in }, receiveValue: { result in
                        if result != [] {
                            promise(.success(result))
                        }
                        else {
                            promise(.failure(.decodingError))
                        }
                })
                return

            }
            promise(.success(filters))

        }.eraseToAnyPublisher()
    }

    private func migrateDatabase() -> Future<[Filter], FilterStoreMigrationError> {
        let migrator = FilterStoreFileMigrator(store: self)
        return Future<[Filter], FilterStoreMigrationError> { promise in
            _ = migrator.migrateV1()
                .sink(receiveCompletion: { _ in }, receiveValue: { filters in
                    return promise(.success(filters))
            })
        }
    }
}


extension FilterStoreFile {
    
    func fetch() -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { [weak self] promise in
            guard
                let self = self,
                let url = self.fileURL else {
                promise(.failure(.loadError))
                return
            }
            
            // Create the filter store if it does not exist
            if(!self.fileExists(url: url)) {
                let filters = [Filter]()
                
                if let errorMessage = self.saveToDisk(filters: filters) {
                    promise(.failure(.diskError(errorMessage)))
                } else {
                    promise(.success(filters))
                }
            }
            
            do {
                let data = try Data(contentsOf: url)
               _ = decodeData(data: data)
                    .sink(receiveCompletion: { _ in }, receiveValue: { result in
                        promise(.success(result))
                    })
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
                    guard let self = self else { return }
                    
                    var filters: [Filter] = result

                    var newFilter = filter
                    
                    // If the filter is not a regular expression
                    if !newFilter.useRegex {
                        newFilter.phrase = newFilter.phrase
                    }
                    filters.append(newFilter)
                    filters = filters.sorted(by: { $1.phrase > $0.phrase })
                    
                    if let errorMessage = self.saveToDisk(filters: filters) {
                        promise(.failure(.diskError(errorMessage)))
                    } else {
                        promise(.success(()))
                    }
                })
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    func addMany(filters: [Filter]) -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { promise in
            self.fetch()
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                    guard let self = self else { return }
                    
                    var existingFilters: [Filter] = result

                    let newFilters = filters.map { f in
                        if (existingFilters.contains(f)) {
                            return Filter(
                                id: UUID(),
                                phrase: f.phrase,
                                type: f.type,
                                action: f.action,
                                subAction: f.subAction,
                                useRegex: f.useRegex
                            )
                        } else {
                            return f
                        }
                    }
                    
                    
                    existingFilters.append(contentsOf: newFilters)
                    existingFilters = existingFilters.sorted(by: { $1.phrase > $0.phrase })
                    
                    if let errorMessage = self.saveToDisk(filters: existingFilters) {
                        promise(.failure(.diskError(errorMessage)))
                    } else {
                        promise(.success(()))
                    }
                })
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    func update(filter: Filter) -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { promise in
            self.fetch()
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                    var filters = result
                    
                    if let filterIndex = result.firstIndex(where: { $0.id == filter.id }) {
                        filters[filterIndex] = filter
                        
                        if let errorMessage = self?.saveToDisk(filters: filters) {
                            promise(.failure(.diskError(errorMessage)))
                        } else {
                            promise(.success(()))
                        }
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
                    
                    if let errorMessage = self?.saveToDisk(filters: filters) {
                        promise(.failure(.diskError(errorMessage)))
                    } else {
                        promise(.success(()))
                    }
                })
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    func reset() -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { [weak self] promise in
            if let errorMessage = self?.saveToDisk(filters: []) {
                promise(.failure(.diskError(errorMessage)))
            } else {
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    
}
