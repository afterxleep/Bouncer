//
//  FilterReducer.swift
//  Bouncer
//

import Foundation
import Combine

func filterReducer(state: inout FilterState, action: FilterAction) -> AnyPublisher<AppAction, Never>? {
    switch action {

    case let .setFilters(filters):
        state.filters = filters

    case .load:
        break

    case .remove(let uuid):
        return nil
    }

    return Empty().eraseToAnyPublisher()
}
