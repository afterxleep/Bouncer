//
//  String+Localized.swift
//  Bouncer
//
//  Created by Miguel Rojas Cortes on 4/6/21.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
