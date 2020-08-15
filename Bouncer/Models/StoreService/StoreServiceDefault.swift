//
//  StoreServiceDefault.swift
//  Bouncer
//

import Foundation
import StoreKit
import Combine

struct Product {
    var identifier: String
    var title: String
    var description: String
    var price: String
}

enum TransactionState {
    case notStarted
    case purchasing
    case purchased
    case failed
    case restored
}

class StoreServiceDefault: ObservableObject {

    internal var storeManager = StoreManager.shared
    internal var storeObserver = StoreObserver.shared
    private var skProducts: [SKProduct] = []
    
    var productIdentifiers = ["com.banshai.bouncer.unlimited_filters"]
    var productsCancellable: AnyCancellable?
    var transactionStateCancellable: AnyCancellable?
    
    // Publishers
    @Published private(set) var products: [Product] = []
    var productsPublisher: Published<[Product]>.Publisher { $products }
    @Published private(set) var transactionState: StoreTransactionState = .notInitiated
    var transactionStatePublisher: Published<StoreTransactionState>.Publisher { $transactionState }
    
    
    init() {
        productsCancellable =
            storeManager
                .$availableProducts
                .receive(on: RunLoop.main)
                .sink { [weak self] products in
                    self?.skProducts = products
                    self?.products = self?.parseProducts(from: products) ?? []
            }
        
        transactionStateCancellable =
            storeObserver
                .$transactionResult
                .receive(on: RunLoop.main)
                .sink { [weak self] state in
                    self?.transactionState = state
                    print(state)
                }
        
        self.fetchProducts()
    }
}

extension StoreServiceDefault: StoreService {
    
    func fetchProducts() {
        storeManager.startProductRequest(with: productIdentifiers)
    }
    
    func startPurchase(product: Product) {
        guard let product = skProducts.first(
                where: { $0.productIdentifier == product.identifier})
        else {
            print("Product not found")
            return
        }
        StoreObserver.shared.buy(product)
    }
    
    func restorePurchases() {
        StoreObserver.shared.restore()
    }
}
    
extension StoreServiceDefault {
    
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
                                        price: formattedPrice)
            result.append(p)
        }
        return result
        
    }
}
