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
        state.filterImportInProgress = false

    case .decodeComplete(let filters):
        state.importedFilters = filters
        state.filterImportInProgress = true

    case .error(let error):
        state.filterError = error
        state.filterImportInProgress = false

    case .clearError:
        state.filterError = nil        

    default:
        break
    }

}
