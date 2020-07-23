//
//  StoreServiceDefault.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/21/20.
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
    var storeObserverCancellable: AnyCancellable?
    
    // Publishers
    @Published private(set) var products: [Product] = []
    var productsPublisher: Published<[Product]>.Publisher { $products }
    
    init() {
        print("initializing")
        productsCancellable =
            storeManager
                .$availableProducts
                .receive(on: RunLoop.main)
                .sink { [weak self] products in
                    self?.skProducts = products
                    self?.products = self?.parseProducts(from: products) ?? []
            }
        
        storeObserverCancellable =
            storeObserver
                .$transactionResult
            .receive(on: RunLoop.main)
            .sink { [weak self] transactionResult in
                print(transactionResult)
            }
        
        self.fetchProducts()
    }
}

extension StoreServiceDefault: StoreServiceProtocol {
    
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
    
    func completePurchase(result: TransactionState) {}
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
