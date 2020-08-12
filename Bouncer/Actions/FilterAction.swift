//
//  FilterAction.swift
//  Bouncer
//

import Foundation

enum FilterAction {
    case setFilters(filters: [Filter])
    case load
    case remove(uuid: UUID)
}
