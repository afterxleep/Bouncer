//
//  SMSFilter.swift
//  Bouncer
//


import Foundation
import IdentityLookup

protocol SMSFiltering {
    var filters: [Filter] { get }
    var filterListService: FilterStore { get }
    func filterMessage(message: SMSMessage) -> ILMessageFilterAction
}
