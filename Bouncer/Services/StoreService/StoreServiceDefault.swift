//
//  StoreServiceDefault.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/21/20.
//

import Foundation
import StoreKit

struct Product {
    var identifier: String
    var title: String
    var description: String
    var price: String
}

class StoreServiceDefault: NSObject, StoreServiceProtocol, ObservableObject {
    
    private var productIdentifiers = ["com.banshai.bouncer.unlimited_filters"]
    private var skProductRequest: SKProductsRequest!
    
    // Product Publisher
    @Published private(set) var products: [Product] = []
    var productsPublisher: Published<[Product]>.Publisher { $products }
    
    override init() {
        super.init()
        fetchProducts(matchingIdentifiers: self.productIdentifiers)
    }

    // Fetches information about your products from the App Store.
    fileprivate func fetchProducts(matchingIdentifiers identifiers: [String]) {
        // Create a set for the product identifiers.
        let productIdentifiers = Set(identifiers)
        
        // Initialize the product request with the above identifiers.
        skProductRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        skProductRequest.delegate = self
        
        // Send the request to the App Store.
        skProductRequest.start()
    }
    
    fileprivate func parseProducts(from products: [SKProduct]) -> [Product] {
        var result: [Product] = []
        for product in products {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceLocale
            let price = formatter.string(from: product.price) ?? ""
            let p = Product(identifier: product.productIdentifier,
                                        title: product.localizedTitle,
                                        description: product.localizedDescription,
                                        price: price)
            result.append(p)
        }
        return result
    }
}

extension StoreServiceDefault: SKProductsRequestDelegate {
            
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty {
            products = parseProducts(from: response.products)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
      print("Request didFailWithError ",error)
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("Request didFinish")
    }
    
}
