//
//  Filter.swift
//  Bouncer
//
//  Created by Daniel on 22/04/23.
//

import Foundation

struct FilterV1: Identifiable, Equatable, Codable {
    var id: UUID
    var type: FilterType
    var phrase: String
    var action: FilterDestination
    var useRegex: Bool?

    init(id: UUID,
         phrase: String,
         type: FilterType = .any,
         action: FilterDestination = .junk,
         useRegex: Bool? = nil
    ) {
        self.id = id
        self.type = type
        self.phrase = phrase
        self.action = action
        self.useRegex = useRegex
    }
}
