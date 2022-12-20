//
//  FilterReducer.swift
//  Bouncer
//

import Foundation

func filterReducer(state: inout FilterState, action: FilterAction) -> Void {
    switch action {

    case .fetchComplete(let filters):
        state.filters = filters
        
    case .import(let filters):
        state.importedFilters = filters
        
    default:
        break
    }

}
