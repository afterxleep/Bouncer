//
//  DispatchQueue.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/24/20.
//

import Foundation
import Combine

extension DispatchQueue {
 
    /// Dispatch block asynchronously
    /// - Parameter block: Block

    func publisher<Output, Failure: Error>(_ block: @escaping (Future<Output, Failure>.Promise) -> Void) -> AnyPublisher<Output, Failure> {
        Future<Output, Failure> { promise in
            self.async { block(promise) }
        }.eraseToAnyPublisher()
    }
}
