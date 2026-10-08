//
//  FilterStoreFile.swift
//  Bouncer
//

import Foundation
import Combine
import os.log

final class FilterStoreFile: FilterStore {

    static let filterListFile = "filters.json"
    static let groupContainer = "group.com.banshai.bouncer"
    static let filterListFileV1 = "wordlist.filter"

    enum FetchPolicy {
        case createIfMissing
        case preserve
    }

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
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Write the given filters atomically to the shared store.
    ///
    /// Returns `nil` on success; an error message on failure. A `nil`
    /// `fileURL` is itself an error (the app-group container is missing) and
    /// is reported as such, never as a silent success.
    private func saveToDisk(filters: [Filter]) -> FilterStoreError? {
        guard let url = fileURL else {
            return .diskError("App group container unavailable")
        }

        do {
            let data = try JSONEncoder().encode(filters)
            try data.write(to: url, options: [.atomic])
            return nil
        } catch {
            let errorMessage = error.localizedDescription
            os_log("Error: %s.", type: .error, errorMessage)
            return .diskError(errorMessage)
        }
    }

    /// A malformed current file must not be reinterpreted as V1 and rewritten.
    private func decodeData(data: Data) -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { promise in
            if let filters = try? JSONDecoder().decode([Filter].self, from: data) {
                promise(.success(filters))
            } else {
                promise(.failure(.loadError))
            }
        }
        .eraseToAnyPublisher()
    }
}


extension FilterStoreFile {

    func fetch() -> AnyPublisher<[Filter], FilterStoreError> {
        return fetch(policy: .createIfMissing)
    }

    /// The extension reads without creating a store on first launch.
    func fetch(policy: FetchPolicy) -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.loadError))
                return
            }
            guard let url = self.fileURL else {
                promise(.failure(.loadError))
                return
            }

            // First-launch bootstrap: create an empty file so the rest of the
            // pipeline sees a parseable payload. Only the app does this —
            // the extension's preserve policy keeps the store untouched.
            if !self.fileExists(url: url) {
                if policy == .preserve {
                    promise(.success([]))
                    return
                }
                if let error = self.saveToDisk(filters: []) {
                    promise(.failure(error))
                    return
                }
                promise(.success([]))
                return
            }

            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                promise(.failure(.loadError))
                return
            }

            _ = self.decodeData(data: data)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { result in
                    promise(.success(result))
                })
        }
        .eraseToAnyPublisher()
    }

    func add(filter: Filter) -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { promise in
            self.fetch()
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { [weak self] result in
                    guard let self = self else {
                        promise(.failure(.other))
                        return
                    }
                    var filters: [Filter] = result
                    filters.append(filter)
                    filters = filters.sorted(by: { $1.phrase > $0.phrase })

                    if let error = self.saveToDisk(filters: filters) {
                        promise(.failure(error))
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
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { [weak self] result in
                    guard let self = self else {
                        promise(.failure(.other))
                        return
                    }
                    var existingFilters: [Filter] = result

                    let newFilters = filters.map { f in
                        if existingFilters.contains(f) {
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

                    if let error = self.saveToDisk(filters: existingFilters) {
                        promise(.failure(error))
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
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { [weak self] result in
                    guard let self = self else {
                        promise(.failure(.other))
                        return
                    }
                    var filters = result
                    guard let filterIndex = filters.firstIndex(where: { $0.id == filter.id }) else {
                        promise(.failure(.updateError))
                        return
                    }
                    filters[filterIndex] = filter

                    if let error = self.saveToDisk(filters: filters) {
                        promise(.failure(error))
                    } else {
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
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { [weak self] result in
                    guard let self = self else {
                        promise(.failure(.other))
                        return
                    }
                    var filters: [Filter] = result
                    filters = filters.filter { $0.id != uuid }

                    if let error = self.saveToDisk(filters: filters) {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                })
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    func reset() -> AnyPublisher<Void, FilterStoreError> {
        return Future<Void, FilterStoreError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.other))
                return
            }
            if let error = self.saveToDisk(filters: []) {
                promise(.failure(error))
            } else {
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func decodeFromURL(url: URL) -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { promise in
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let filters = try JSONDecoder().decode([Filter].self, from: Data(contentsOf: url))
                promise(.success(filters))
            } catch {
                promise(.failure(.decodingError))
            }
        }.eraseToAnyPublisher()
    }

    /// Used by the V1 migrator to write the fully-migrated array in a single
    /// atomic write. Not on the public `FilterStore` protocol — it is a
    /// filesystem-implementation seam that mirrors `reset()` but for a given
    /// list, so the migration can replace the legacy payload in one operation
    /// rather than one store call per filter.
    func resolveMigration(filters: [Filter]) -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.other))
                return
            }
            if let error = self.saveToDisk(filters: filters) {
                promise(.failure(error))
            } else {
                self.filters = filters
                promise(.success(filters))
            }
        }
        .eraseToAnyPublisher()
    }
}
