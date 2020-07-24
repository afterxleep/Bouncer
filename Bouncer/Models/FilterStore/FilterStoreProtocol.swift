//
//  FilterStoreService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/1/20.
//

import Foundation
import Combine

enum FilterType: String, Codable, Equatable, CaseIterable {
    case any
    case sender
    case message
}

enum FilterDestination: String, Codable, Equatable, CaseIterable {
    case junk
    case transaction
    case promotion
}

struct Filter: Identifiable, Equatable, Codable {
    var id: UUID
    var type: FilterType
    var phrase: String
    var action: FilterDestination
    
    init(id: UUID, phrase: String, type: FilterType = .any, action: FilterDestination = .junk) {
        self.id = id
        self.type = type
        self.phrase = phrase.lowercased()
        self.action = action
    }
}

enum FilterStoreError: Error {
    case loadError
    case decodingError
    case addError
    case deleteError
    case other
}


protocol FilterStoreProtocol {
    func get() -> AnyPublisher<[Filter], FilterStoreError>
    func add(filter: Filter)
    func remove(id: UUID) -> Empty<Any, Never>
    func reset()
    func migrateFromV1()
}
