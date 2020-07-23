import StoreKit
import Foundation

class StoreManager: NSObject, ObservableObject {
    
    // MARK: - Types
    
    static let shared = StoreManager()
    
    // MARK: - Published Props
    
    @Published private(set) var availableProducts: [SKProduct] = []
    @Published private(set) var invalidProductIdentifiers: [String] = []
    
    // MARK: - Properties
        
    /// Keeps a strong reference to the product request.
    fileprivate var productRequest: SKProductsRequest!
        
    // MARK: - Initializer
    
    private override init() {}
    
    // MARK: - Request Product Information
    
    /// Starts the product request with the specified identifiers.
    func startProductRequest(with identifiers: [String]) {
        fetchProducts(matchingIdentifiers: identifiers)
    }
    
    /// Fetches information about your products from the App Store.
    /// - Tag: FetchProductInformation
    fileprivate func fetchProducts(matchingIdentifiers identifiers: [String]) {
        // Create a set for the product identifiers.
        let productIdentifiers = Set(identifiers)
        
        // Initialize the product request with the above identifiers.
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self
        
        // Send the request to the App Store.
        productRequest.start()
    }
    
    // MARK: - Helper Methods
    
    /// - returns: Existing product's title matching the specified product identifier.
    func title(matchingIdentifier identifier: String) -> String? {
        var title: String?
        guard !availableProducts.isEmpty else { return nil }
        
        // Search availableProducts for a product whose productIdentifier property matches identifier. Return its localized title when found.
        let result = availableProducts.filter({ (product: SKProduct) in product.productIdentifier == identifier })
        
        if !result.isEmpty {
            title = result.first!.localizedTitle
        }
        return title
    }
    
    /// - returns: Existing product's title associated with the specified payment transaction.
    func title(matchingPaymentTransaction transaction: SKPaymentTransaction) -> String {
        let title = self.title(matchingIdentifier: transaction.payment.productIdentifier)
        return title ?? transaction.payment.productIdentifier
    }
}

// MARK: - SKProductsRequestDelegate

/// Extends StoreManager to conform to SKProductsRequestDelegate.
extension StoreManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        if !response.products.isEmpty {
            availableProducts = response.products
        }
        
        if !response.invalidProductIdentifiers.isEmpty {
            invalidProductIdentifiers = response.invalidProductIdentifiers
        }
    }
}

// MARK: - SKRequestDelegate
extension StoreManager: SKRequestDelegate {
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Request Failed")
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("Request Complete")
    }
}
