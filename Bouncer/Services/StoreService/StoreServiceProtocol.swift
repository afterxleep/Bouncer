//
//  StoreServiceProtocol.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/21/20.
//

import Foundation
import StoreKit

protocol StoreServiceProtocol {
    var products: [Product] { get }
    var productsPublisher: Published<[Product]>.Publisher { get }
}
