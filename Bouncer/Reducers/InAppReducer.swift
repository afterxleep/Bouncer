//
//  InAppReducer.swift
//  Bouncer
//

import Foundation

func inAppReducer(state: inout InAppState, action: InAppAction) -> Void {

    switch action {

        case .fetchProducts:
            state.transactionInProgress = true

        case .fetchProductsComplete(let products):
            state.transactionInProgress = false
            state.availableProducts = products
            break

        case .fetchProductsError(let error):
            break

        case .purchaseProduct(let product):
            state.transactionInProgress = true

        case .purchaseProductComplete(let product):
            state.transactionInProgress = false

        case .purchaseProductError(let error):
            break

        case .restorePurchase:
            state.transactionInProgress = true

        case .restorePurchaseComplete:
            state.transactionInProgress = false

        case .restorePurchaseError(let error):
            break
        }

}
