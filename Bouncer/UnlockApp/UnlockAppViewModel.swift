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
    @Published private(set) var shouldDisplayBuyButton: Bool = true
    @Published private(set) var transactionCompletedSuccessdfully: Bool = false
    
    init(storeService: StoreServiceProtocol = StoreServiceDefault()) {
        self.storeService = storeService        
        
        productsCancellable =
            storeService
                .productsPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] products in
                    self?.products = products
            }
        
        transactionStateCancellable =
            storeService
                .transactionStatePublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] state in
                    self?.manageTransactionCompletion(state: state)
            }
    }
    
    func purchase(product: Product) {
        self.shouldDisplayBuyButton = false
        storeService.startPurchase(product: product)
    }
    
    func restorePurchases() {
        self.shouldDisplayBuyButton = false
        storeService.restorePurchases()
    }
    
    func manageTransactionCompletion(state: StoreTransactionState) {
        switch state {
        case .notInitiated, .cancelled, .failed, .restoreFailed, .processing:
            self.shouldDisplayBuyButton = true
        case .completed, .restored:
            self.transactionCompletedSuccessdfully = true
        }
    }
}
