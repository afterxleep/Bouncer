//
//  Extensions.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/22/20.
//

import Foundation
import StoreKit

// MARK: - DateFormatter

extension DateFormatter {
    /// - returns: A string representation of date using the short time and date style.
    class func short(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    /// - returns: A string representation of date using the long time and date style.
    class func long(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        return dateFormatter.string(from: date)
    }
}

// MARK: - Section

extension ProductSection {
    /// - returns: A Section object matching the specified name in the data array.
    static func parse(_ data: [ProductSection], for type: SectionType) -> ProductSection? {
        let section = (data.filter({ (item: ProductSection) in item.type == type }))
        return (!section.isEmpty) ? section.first : nil
    }
}

// MARK: - SKProduct
extension SKProduct {
    /// - returns: The cost of the product formatted in the local currency.
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}

extension SKDownload {
    /// - returns: A string representation of the downloadable content length.
    var downloadContentSize: String {
        return ByteCountFormatter.string(fromByteCount: self.expectedContentLength, countStyle: .file)
    }
}
