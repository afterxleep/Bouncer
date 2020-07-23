//
//  UnlockAppViewModel.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/21/20.
//

import Foundation
import Combine

class UnlockAppViewModel: ObservableObject {
    
    let storeService: StoreServiceProtocol
    var productsCancellable: AnyCancellable?
    var transactionStateCancellable: AnyCancellable?
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var transactionState: TransactionState = .notStarted
    
    init(storeService: StoreServiceProtocol = StoreServiceDefault()) {
        self.storeService = storeService
        
        productsCancellable =
            storeService
                .productsPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] products in
                    self?.products = products
            }
        storeService.fetchProducts()
    }
}
