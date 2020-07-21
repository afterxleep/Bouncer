//
//  FilterStoreService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/1/20.
//

import Foundation

protocol FilterStoreProtocol {
    var filters: [Filter] {get set}
    
    // Property wrapper @Published is not supported in protocols,
    // so we need to explicitly describe the synthesized props
    var filtersPublished: Published<[Filter]> { get }
    var filtersPublisher: Published<[Filter]>.Publisher { get }
    
    func add(filter: Filter)
    func remove(id: UUID)
    func reset()
    func migrateFromV1()
}
