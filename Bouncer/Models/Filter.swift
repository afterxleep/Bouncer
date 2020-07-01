//
//  Word.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import Foundation

enum FilterType: String, Codable, Equatable, CaseIterable {
    case any
    case sender
    case message
}

enum FilterAction: String, Codable, Equatable, CaseIterable {
    case junk
    case transaction
    case promotion
}

struct Filter: Identifiable, Equatable, Codable {
    var id: UUID
    var type: FilterType
    var phrase: String
    var action: FilterAction
    
    init(id: UUID, phrase: String, type: FilterType = .any, action: FilterAction = .junk) {
        self.id = id
        self.type = type
        self.phrase = phrase.lowercased()
        self.action = action
    }
}
