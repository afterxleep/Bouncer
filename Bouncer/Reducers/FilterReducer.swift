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

    case .fetchError(let error):
        state.filterError = mapMiddlewareError(error)
        state.filterImportInProgress = false

    case .addError(let error):
        state.filterError = mapMiddlewareError(error)

    case .addManyError(let error):
        state.filterError = mapMiddlewareError(error)

    case .updateError(let error):
        state.filterError = mapMiddlewareError(error)

    case .deleteError(let error):
        state.filterError = mapMiddlewareError(error)

    case .error(let error):
        state.filterError = error
        state.filterImportInProgress = false

    case .clearError:
        state.filterError = nil

    default:
        break
    }

}

private func mapMiddlewareError(_ error: FilterMiddlewareError) -> FilterError {
    switch error {
    case .decodingError:
        return .decodingFailed(reason: "INCORRECT_FILE_FORMAT")
    case .loadError:
        return .loadFailed
    case .addError, .addManyError, .updateError:
        return .saveFailed
    case .deleteError:
        return .deleteFailed
    case .unknown(let message):
        return .diskError(message: message)
    }
}
