//
//  FilterAction.swift
//  Bouncer
//

import Foundation

enum FilterAction {
    case fetch
    case fetchComplete(filters: [Filter])
    case fetchError(error: FilterMiddlewareError)
    case remove(uuid: UUID)
    case add(filter: Filter)
}
