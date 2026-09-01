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

    /// Policy applied on a decode failure. The app may heal the store so the
    /// next launch is clean; the MessageFilterExtension never gets a UI to
    /// show the user, so it must use `.preserve` and leave the on-disk bytes
    /// alone. A destructive write from the extension silently wipes every
    /// rule.
    enum FetchHealPolicy {
        /// The store may quarantine the corrupt bytes and overwrite
        /// `filters.json` with a fresh empty payload so the next launch is
        /// clean. Reserved for the app process.
        case heal
        /// The store must never write `filters.json` and must never create
        /// any sidecar. Required for the MessageFilterExtension: the user
        /// is never told a heal happened, and silently destroying their
        /// rules is data loss.
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
        guard let url = self.fileURL else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Move the corrupt bytes at `url` to a sibling sidecar named
    /// `filters.json.corrupt-<timestamp>` so a partially-recoverable file
    /// can be salvaged by hand. The move uses `FileManager.moveItem` so
    /// the original location is empty after the call and a subsequent
    /// write at the original path succeeds.
    ///
    /// Failure is logged but never surfaced: a quarantine miss must not
    /// block the heal that the user is waiting for. The worst case is the
    /// user sees the alert and the bytes are gone, the same outcome as
    /// before this fix.
    private func quarantineCorruptBytes(at url: URL) {
        let container = url.deletingLastPathComponent()
        let timestamp = Self.quarantineTimestamp()
        let sidecar = container.appendingPathComponent("filters.json.corrupt-\(timestamp)")
        do {
            try FileManager.default.moveItem(at: url, to: sidecar)
        } catch {
            os_log("Failed to quarantine corrupt store: %s.", type: .error, error.localizedDescription)
        }
    }

    private static func quarantineTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss'Z'"
        return formatter.string(from: Date())
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

    /// Decode the on-disk bytes. On a fresh-format failure, run the V1
    /// migration. On any failure, complete exactly once with `.loadError`.
    private func decodeData(data: Data) -> AnyPublisher<[Filter], FilterStoreError> {
        return Future<[Filter], FilterStoreError> { promise in
            if let filters = try? JSONDecoder().decode([Filter].self, from: data) {
                promise(.success(filters))
                return
            }

            _ = self.migrateDatabase()
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        promise(.failure(.loadError))
                    }
                }, receiveValue: { result in
                    promise(.success(result))
                })
        }
        .eraseToAnyPublisher()
    }

    private func migrateDatabase() -> AnyPublisher<[Filter], FilterStoreMigrationError> {
        let migrator = FilterStoreFileMigrator(store: self)
        return migrator.migrateV1()
    }
}


extension FilterStoreFile {

    func fetch() -> AnyPublisher<[Filter], FilterStoreError> {
        return fetch(policy: .heal)
    }

    /// Read the on-disk store, with a policy for what to do on a decode
    /// failure. The app calls `fetch()` (heal); the MessageFilterExtension
    /// calls `fetch(policy: .preserve)` so its failure path never writes.
    func fetch(policy: FetchHealPolicy) -> AnyPublisher<[Filter], FilterStoreError> {
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
                        if policy == .heal {
                            // Quarantine the corrupt bytes to a sidecar
                            // before overwriting, so a partially-recoverable
                            // file can still be salvaged. The extension
                            // reaches this path only under .heal, never
                            // .preserve, so a destructive write from the
                            // extension process is impossible.
                            self.quarantineCorruptBytes(at: url)
                            _ = self.saveToDisk(filters: [])
                        }
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
