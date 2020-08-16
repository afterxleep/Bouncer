//
//  StoreServiceDefault.swift
//  Bouncer
//

import Foundation
import StoreKit
import Combine

struct StoreServiceDefault {

    internal var storeManager = StoreManager.shared
    internal var storeObserver = StoreObserver.shared
    var productIdentifiers = ["com.banshai.bouncer.unlimited_filters"]

    fileprivate func transactionObserver() -> AnyPublisher<TransactionState, Never> {
        return storeObserver
            .$transactionResult
            .map({ state in
                switch(state) {
                case .processing:
                    return .purchasing
                case .completed, .restored:
                    return .purchased
                case .notInitiated:
                    return .notStarted
                case .failed, .restoreFailed:
                    return .failed
                case .cancelled:
                    return .notStarted
                }
            }).eraseToAnyPublisher()
    }

    fileprivate func parseProducts(from products: [SKProduct]) -> [Product] {
        var result: [Product] = []
        for product in products {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceLocale
            let formattedPrice = formatter.string(from: product.price) ?? ""
            let p = Product(identifier: product.productIdentifier,
                                        title: product.localizedTitle,
                                        description: product.localizedDescription,
                                        price: formattedPrice,
                                        skProduct: product)
            result.append(p)
        }
        return result

    }

}

extension StoreServiceDefault: StoreService {
    
    func fetchProducts() -> AnyPublisher<[Product], Never> {
        storeManager.startProductRequest(with: productIdentifiers)
        return storeManager
            .$availableProducts
            .map({ products -> [Product] in
                let parsedProducts = self.parseProducts(from: products)
                return parsedProducts
            }).eraseToAnyPublisher()
    }

    func startPurchase(product: Product) -> AnyPublisher<TransactionState, Never> {
        StoreObserver.shared.buy(product.skProduct)
        return transactionObserver()
    }
    
    func restorePurchases()-> AnyPublisher<TransactionState, Never> {
        StoreObserver.shared.restore()
        return transactionObserver()

    }
}
