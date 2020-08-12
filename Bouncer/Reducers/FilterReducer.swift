//
//  FilterReducer.swift
//  Bouncer
//

import Foundation
import Combine

func filterReducer(state: inout FilterState, action: FilterAction) -> Void {
    switch action {

    case let .setFilters(filters):
        state.filters = filters

    case .load:
        break

    case .remove(let uuid):
        break
    }


}
