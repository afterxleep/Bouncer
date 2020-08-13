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

    case .fetchComplete(let filters):
        state.filters = filters

    case .add:
        break

    case .fetchError(let error):
        break

    case .remove:
        break

    }

}
