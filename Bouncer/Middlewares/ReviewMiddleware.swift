//
//  ReviewMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

func reviewMiddleware(reviewService: ReviewService) -> Middleware<AppState, AppAction> {

    return { state, action in
        switch action {

        case .filter(action: .add(_)):
            var r = reviewService
            r.requestReview()

        default:
            break

        }
        return Empty().eraseToAnyPublisher()
    }

}
