//
//  FilterStoreMigrator.swift
//  Bouncer
//
//  Created by Daniel on 22/04/23.
//

import Foundation
import Combine

enum FilterStoreMigrationError: Error {
    case loadError
}

struct FilterStoreFileMigrator {

    let store: FilterStoreFile

    init(store: FilterStoreFile) {
        self.store = store
    }

    /// One-shot V1 → V2 migration.
    ///
    /// Reads the on-disk V1 payload, transforms it in memory, then writes the
    /// whole migrated list atomically in a single `saveToDisk` call. The old
    /// data is only considered replaced once the new data is durably on disk;
    /// an interruption before the write leaves the original bytes intact.
    func migrateV1() -> AnyPublisher<[Filter], FilterStoreMigrationError> {
        return Future<[Filter], FilterStoreMigrationError> { [store] promise in
            guard let url = FilterStoreFile.fileURL else {
                promise(.failure(.loadError))
                return
            }
            guard let data = try? Data(contentsOf: url),
                  let legacy = try? JSONDecoder().decode([FilterV1].self, from: data) else {
                promise(.failure(.loadError))
                return
            }

            let migrated = legacy.map { filter -> Filter in
                let subAction: FilterDestination
                switch filter.action {
                case .promotion:
                    subAction = .promotionOther
                case .transaction:
                    subAction = .transactionOther
                default:
                    subAction = .none
                }
                return Filter(id: filter.id,
                              phrase: filter.phrase,
                              type: filter.type,
                              action: filter.action,
                              subAction: subAction,
                              useRegex: filter.useRegex ?? false,
                              caseSensitive: false)
            }
            .sorted(by: { $1.phrase > $0.phrase })

            // Persist through the store so the same atomic write path is used
            // for every save. resolveMigration does one fetch (to mutate the
            // in-memory cache) then one atomic saveToDisk. The legacy bytes are
            // not overwritten by an empty array — they are replaced by the
            // fully-migrated list in a single write.
            store.resolveMigration(filters: migrated)
                .sink(receiveCompletion: { completion in
                    if case .failure = completion {
                        promise(.failure(.loadError))
                    }
                }, receiveValue: { filters in
                    promise(.success(filters))
                })
        }
        .eraseToAnyPublisher()
    }
}
