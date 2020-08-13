//
//  FilterReducer.swift
//  Bouncer
//

import Foundation
import Combine

func filterReducer(state: inout FilterState, action: FilterAction) -> Void {
    switch action {

    case .fetch:
        break

    case let .fetchComplete(filters):
        state.filters = filters

    case .fetchError(let error):
        break

    case .remove(let uuid):
        break


    }

}
