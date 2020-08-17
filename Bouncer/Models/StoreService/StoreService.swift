//
//  StoreServiceProtocol.swift
//  Bouncer
//

import Foundation
import Combine
import StoreKit

struct Product {
    var identifier: String
    var title: String
    var description: String
    var price: String
    var skProduct: SKProduct
}

enum TransactionState {
    case notStarted
    case purchasing
    case purchased
    case failed
    case restored
}

protocol StoreService {
    var productIdentifiers: [String] { get set }
    var storeManager: StoreManager { get set }
    func fetchProducts() -> AnyPublisher<[Product], Never>
    func startPurchase(product: Product) -> AnyPublisher<TransactionState, Never>
    func restorePurchases() -> AnyPublisher<TransactionState, Never>
}
