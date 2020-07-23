//
//  StoreServiceProtocol.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/21/20.
//

import Foundation

protocol StoreServiceProtocol {
    
    var productIdentifiers: [String] { get set }
    var storeManager: StoreManager { get set }    
    
    var products: [Product] { get }
    var productsPublisher: Published<[Product]>.Publisher { get }
    
    func fetchProducts()
    func startPurchase(product: Product)
    
}
