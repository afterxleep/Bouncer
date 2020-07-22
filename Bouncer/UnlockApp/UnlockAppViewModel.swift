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
    
    @Published private(set) var products: [Product] = []
    
    init(storeService: StoreServiceProtocol = StoreServiceDefault()) {
        self.storeService = storeService
        
        productsCancellable =
                    storeService
                        .productsPublisher
                        .receive(on: RunLoop.main)
                        .sink { [weak self] data in
                            self?.products = data
                    }
    }
    
}
