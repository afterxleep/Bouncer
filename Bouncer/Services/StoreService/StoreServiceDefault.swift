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
    
    var productIdentifiers = ["com.banshai.bouncer.unlimited_filters"]
    var storeManager = StoreManager.shared
    
    // Publishers
    @Published private(set) var products: [Product] = []
    var productsPublisher: Published<[Product]>.Publisher { $products }
    @Published var purchasedProducts: [Product] = []
    
    var productsCancellable: AnyCancellable?
    
    init() {
        productsCancellable =
            storeManager
                .$availableProducts
                .receive(on: RunLoop.main)
                .sink { [weak self] products in                    
                    self?.products = self?.parseProducts(from: products) ?? []
            }
    }
}

extension StoreServiceDefault: StoreServiceProtocol {
    
    func fetchProducts() {
        storeManager.startProductRequest(with: productIdentifiers)
    }
    
    func startPurchase(product: Product) {}
    func completePurchase(result: TransactionState) {}
}

extension StoreServiceDefault: StoreObserverDelegate {
    
    func storeObserverRestoreDidSucceed() {}
    func storeObserverDidReceiveMessage(_ message: String) {}
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
