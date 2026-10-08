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
    case allow
    case junk
    case transaction
    case promotion

    // SubActions
    case transactionOrder
    case transactionFinance
    case transactionReminders
    case transactionHealth
    case transactionOther
    case promotionOffers
    case promotionCoupons
    case promotionOther

}

struct Filter: Hashable, Identifiable, Equatable, Codable {
    var id: UUID
    var type: FilterType
    var phrase: String
    var action: FilterDestination
    var subAction: FilterDestination
    var caseSensitive: Bool = false
    var useRegex: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id, type, phrase, action, subAction, caseSensitive, useRegex
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        type = try values.decode(FilterType.self, forKey: .type)
        phrase = try values.decode(String.self, forKey: .phrase)
        action = try values.decode(FilterDestination.self, forKey: .action)
        if let storedSubAction = try values.decodeIfPresent(FilterDestination.self, forKey: .subAction) {
            subAction = storedSubAction
        } else {
            switch action {
            case .promotion: subAction = .promotionOther
            case .transaction: subAction = .transactionOther
            default: subAction = .none
            }
        }
        caseSensitive = try values.decodeIfPresent(Bool.self, forKey: .caseSensitive) ?? false
        useRegex = try values.decodeIfPresent(Bool.self, forKey: .useRegex) ?? false
    }

    init(id: UUID,
         phrase: String,
         type: FilterType = .any,
         action: FilterDestination = .junk,
         subAction: FilterDestination = .none,
         useRegex: Bool = false,
         caseSensitive: Bool = false
    ) {
        self.id = id
        self.type = type
        self.phrase = phrase
        self.action = action
        self.subAction = subAction
        self.useRegex = useRegex
        self.caseSensitive = caseSensitive
    }
}

extension Array where Element == Filter {

    func allowList() -> [Filter] {
        return self.filter { $0.action == .allow }
    }

    func blockList() -> [Filter] {
        return self.filter { $0.action != .allow }
    }

}


enum FilterStoreError: Error {
    case loadError
    case decodingError
    case addError
    case updateError
    case deleteError
    case diskError(String)
    case other    
}

protocol FilterStore {
    func fetch() -> AnyPublisher<[Filter], FilterStoreError>
    func add(filter: Filter) -> AnyPublisher<Void, FilterStoreError>
    func addMany(filters: [Filter]) -> AnyPublisher<Void, FilterStoreError>
    func update(filter: Filter) -> AnyPublisher<Void, FilterStoreError>
    func remove(uuid: UUID) -> AnyPublisher<Void, FilterStoreError>
    func reset() -> AnyPublisher<Void, FilterStoreError>
    func decodeFromURL(url: URL) -> AnyPublisher<[Filter], FilterStoreError>
}
