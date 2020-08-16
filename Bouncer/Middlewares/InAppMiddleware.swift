//
//  InAppMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

enum InAppMiddlewareError {
    case purchaseError
    case restoreError
    case fetchError
    case unknown
}

func inAppMiddleware(storeService: StoreService) -> Middleware<AppState, AppAction> {

    return { state, action in
        switch action {

        case .inApp(action: .fetchProducts):
            break;
            /*
            // The service should be changed to actually return a promise!!
            _ = storeService
                .productsPublisher
                .map { AppAction.inApp(action: .fetchProductsComplete(products: $0 ))}
                .eraseToAnyPublisher()
            storeService.fetchProducts()
            */

        default:
            break
        }
        return Empty().eraseToAnyPublisher()
    }

}

