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

    func migrateV1() -> Future<Void, FilterStoreMigrationError> {
        return Future<Void, FilterStoreMigrationError> { promise in
            guard let url = FilterStoreFile.fileURL,
              let data = try? Data(contentsOf: url),
              let filters = try? JSONDecoder().decode([FilterV1].self, from: data) else {
                return promise(.failure(.loadError))
            }
            _ = store.reset()
            
            for filter in filters {
                let updatedFilter = Filter(id: filter.id,
                                           phrase: filter.phrase,
                                           type: filter.type,
                                           action: filter.action,
                                           useRegex: filter.useRegex)
                _ = store.add(filter: updatedFilter)
            }
            return promise(.success(()))
        }

    }

}



