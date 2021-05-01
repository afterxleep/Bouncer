//
//  String+Empty.swift
//  Bouncer
//
//  Created by Miguel Rojas Cortes on 4/6/21.
//

import Foundation

extension String {
    
    var isBlank: Bool {
        trimmed.count == 0
    }
    
    var trimmed: String {
        trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
}
