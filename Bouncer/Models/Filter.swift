//
//  Word.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import Foundation

enum FilterType: String, Codable {
    case any
    case sender
    case message
}

struct Filter: Identifiable, Equatable, Codable {
    var id: UUID
    var type: FilterType
    var phrase: String
    var exactMatch: Bool
    
    init(id: UUID, type: FilterType, phrase: String, exactMatch: Bool) {
        self.id = id
        self.type = type
        self.phrase = phrase.lowercased()
        self.exactMatch = exactMatch
    }
}
