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

    func migrateV1() -> AnyPublisher<[Filter], FilterStoreMigrationError> {
        return Future<[Filter], FilterStoreMigrationError> { promise in
            guard let url = FilterStoreFile.fileURL,
              let data = try? Data(contentsOf: url),
              let filters = try? JSONDecoder().decode([FilterV1].self, from: data) else {
                return promise(.failure(.loadError))
            }
            _ = store.reset()

            // Update filters
            for filter in filters {
                var subAction: FilterDestination
                switch filter.action {
                case .promotion:
                    subAction = .promotionOther
                case .transaction:
                    subAction = .transactionOther
                default:
                    subAction = .none
                }
                let updatedFilter = Filter(id: filter.id,
                                           phrase: filter.phrase,
                                           type: filter.type,
                                           action: filter.action,
                                           subAction: subAction,
                                           useRegex: filter.useRegex,
                                           caseSensitive: false)
                print(updatedFilter)
                _ = store.add(filter: updatedFilter)
            }
            // Re-fetch data
            _ = store.fetch()
                .sink(receiveCompletion: { _ in }, receiveValue: { filters in
                    return promise(.success(filters))
                })
        }.eraseToAnyPublisher()
    }

}



