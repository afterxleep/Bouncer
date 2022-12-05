//
//  FilterReducer.swift
//  Bouncer
//

import Foundation

func filterReducer(state: inout FilterState, action: FilterAction) -> Void {
    switch action {

    case .fetchComplete(let filters):
        state.filters = filters
        
    case .fetchFromImportComplete(let filters):
        state.filtersFromImport = filters
        
    default:
        break
    }

}
