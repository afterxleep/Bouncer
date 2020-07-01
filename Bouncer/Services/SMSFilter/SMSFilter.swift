//
//  SMSFilter.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/1/20.
//

import Foundation
import IdentityLookup

protocol SMSFilter {
    var filterListService: FilterStore { get }
    var filters: [Filter] { get }
    func applyFilter(filter: Filter, message: SMSMessage) -> Bool
    func filterMessage(message: SMSMessage) -> ILMessageFilterAction
}
