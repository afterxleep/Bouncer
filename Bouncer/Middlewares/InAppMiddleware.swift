//
//  InAppMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

enum InAppMiddlewareError {
    case purchaseError
    case restoreError
    case fetchError
    case unknown
}

func inAppMiddleware(reviewService: ReviewService) -> Middleware<AppState, AppAction> {

    return { state, action in
        switch action {


            default:
                break
        }
        return Empty().eraseToAnyPublisher()
    }

}

