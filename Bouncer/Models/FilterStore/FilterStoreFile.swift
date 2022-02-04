//
//  FilterStoreFile.swift
//  Bouncer
//

import Foundation
import Combine

private typealias DiskWriteError = String

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
            #if DEBUG
            print(errorMessage)
            #endif
            
            return errorMessage
        }
    }
    
}


extension FilterStoreFile {
    
    func fetch() -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { [weak self] promise in
            var filters: [Filter] = []
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
                    guard let self = self else { return }
                    
                    var filters: [Filter] = result
                    filters.append(filter)
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
