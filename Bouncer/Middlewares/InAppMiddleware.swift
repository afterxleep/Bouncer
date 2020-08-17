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
            return storeService.fetchProducts()
                .map({ products in
                    AppAction.inApp(action: .fetchProductsComplete(products: products))
                }).eraseToAnyPublisher()

        case .inApp(action: .purchaseProduct(let product)):
            return storeService.startPurchase(product: product)
                .map({ response in
                    AppAction.inApp(action: .purchaseProductComplete(product: product))
                }).eraseToAnyPublisher()

        default:
            break
        }
        return Empty().eraseToAnyPublisher()
    }

}

