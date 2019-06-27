//
//  Strings+NSLocalized.swift
//  
//
//  Created by Daniel Bernal on 4/7/19.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
