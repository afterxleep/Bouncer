//
//  InAppaction.swift
//  Bouncer
//

import Foundation

enum InAppAction {
    case fetchProducts
    case fetchProductsComplete(products: [Product])
    case fetchProductsError(error: InAppMiddlewareError)
    case purchaseProduct(product: Product)
    case purchaseProductComplete(product: Product)
    case purchaseProductError(error: InAppMiddlewareError)
    case restorePurchase
    case restorePurchaseComplete
    case restorePurchaseError(error: InAppMiddlewareError)

}
