//
//  FilterAction.swift
//  Bouncer
//

import Foundation

enum FilterAction {
    case fetch
    case fetchComplete(filters: [Filter])
    case fetchError(error: FilterMiddlewareError)
    case add(filter: Filter)
    case addError(error: FilterMiddlewareError)
    case delete(uuid: UUID)
    case deleteError(error: FilterMiddlewareError)

}
