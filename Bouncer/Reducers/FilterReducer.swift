//
//  FilterReducer.swift
//  Bouncer
//

import Foundation
import Combine

func filterReducer(state: inout FilterState, action: FilterAction) -> Void {
    switch action {

    case .fetchComplete(let filters):
        state.filters = filters
        
    default:
        break
    }

}
