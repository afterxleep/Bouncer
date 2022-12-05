//
//  FilterStoreService.swift
//  Bouncer
//

import Foundation
import Combine

enum FilterType: String, Codable, Equatable, CaseIterable {
    case any
    case sender
    case message
}

enum FilterDestination: String, Codable, Equatable, CaseIterable {
    // Base Actions
    case none
    case junk
    case transaction
    case promotion
    
    // SubActions (Apple allows 5 max.)
    case transactionOrder
    case transactionFinance
    case transactionReminders
    case promotionOffers
    case promotionCoupons

}

struct Filter: Hashable, Identifiable, Equatable, Codable {
    var id: UUID
    var type: FilterType
    var phrase: String
    var action: FilterDestination
    var subAction: FilterDestination
    var useRegex: Bool?
    
    init(id: UUID,
         phrase: String,
         type: FilterType = .any,
         action: FilterDestination = .junk,
         subAction: FilterDestination = .none,
         useRegex: Bool? = nil
    ) {
        self.id = id
        self.type = type
        self.phrase = phrase
        self.action = action
        self.subAction = subAction
        self.useRegex = useRegex
    }
}

enum FilterStoreError: Error {
    case loadError
    case decodingError
    case addError
    case updateError
    case deleteError
    case migrationError
    case diskError(String)
    case other
}


protocol FilterStore {
    func fetch() -> AnyPublisher<[Filter], FilterStoreError>
    func add(filter: Filter) -> AnyPublisher<Void, FilterStoreError>
    func update(filter: Filter) -> AnyPublisher<Void, FilterStoreError>
    func remove(uuid: UUID) -> AnyPublisher<Void, FilterStoreError>
    func reset() -> AnyPublisher<Void, FilterStoreError>    
}
