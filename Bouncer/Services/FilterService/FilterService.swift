//
//  FilterService.swift
//  smsfilter
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

protocol FilterService {
    func isValidMessage(message: String?) -> Bool
}
