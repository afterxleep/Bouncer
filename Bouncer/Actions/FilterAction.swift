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
    case addMany(filters: [Filter])
    case addManyError(error: FilterMiddlewareError)
    case update(filter: Filter)
    case updateError(error: FilterMiddlewareError)
    case delete(uuid: UUID)
    case deleteError(error: FilterMiddlewareError)
    case `import`(filters: [Filter])
    case importError(error: FilterMiddlewareError)
}
