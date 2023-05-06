//
//  FilterMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

enum FilterMiddlewareError {
    case loadError
    case addError
    case updateError
    case deleteError
    case unknown
    case decodingError
}

func filterMiddleware(filterStore: FilterStore) -> Middleware<AppState, AppAction> {
    
    return { state, action in
        switch action {
        
        case .filter(action: .fetch):
            return filterStore.fetch()
                .map { AppAction.filter(action: .fetchComplete(filters: $0 )) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .loadError:
                        return Just(AppAction.filter(action: .fetchError(error: FilterMiddlewareError.loadError)))
                        
                    default:
                        return Just(AppAction.filter(action: .fetchError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()
            
        case .filter(action: .add(let filter)):
            return filterStore.add(filter: filter)
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .addError:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.addError)))
                    default:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()

        case .filter(action: .addMany(let filters)):
            return filterStore.addMany(filters: filters)
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .addError:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.addError)))
                    default:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()
            
        case .filter(action: .update(filter: let filter)):
            return filterStore.update(filter: filter)
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch error {
                    case .updateError:
                        return Just(AppAction.filter(action: .updateError(error: .updateError)))
                    default:
                        return Just(AppAction.filter(action: .updateError(error: .unknown)))
                    }
                }
                .eraseToAnyPublisher()
            
        case .filter(action: .delete(let uuid)):
            return filterStore.remove(uuid: uuid)                    
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .addError:
                        return Just(AppAction.filter(action: .deleteError(error: FilterMiddlewareError.deleteError)))
                        
                    default:
                        return Just(AppAction.filter(action: .deleteError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()

        case .filter(action: .loadFromURL(url: let url)):
            return filterStore.decodeFromURL(url: url)
                .map { AppAction.filter(action: .decodeComplete(filters: $0 )) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    default:
                        return Just(AppAction.filter(action: .decodingError(error: FilterMiddlewareError.decodingError)))
                    }
                }
                .eraseToAnyPublisher()

        default:
            break
        }
        return Empty().eraseToAnyPublisher()


    }
    
}
