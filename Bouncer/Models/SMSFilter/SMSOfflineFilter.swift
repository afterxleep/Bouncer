//
//  SMSOfflineFilter.swift
//  Bouncer
//

import Foundation
import IdentityLookup


struct SMSOfflineFilter {

    var filters: [Filter]
    
    //MARK: - Initializer
    init(filterList: [Filter]) {
        self.filters = filterList
    }
    
    fileprivate func applyFilter(filter: Filter, message: SMSMessage) -> Bool {
        var txt = ""
        switch (filter.type) {
            case .sender:
                txt = message.sender.lowercased()
            case .message:
                txt = message.text.lowercased()
            default:
                txt = "\(message.sender.lowercased()) \(message.text.lowercased())"
        }
        return txt.contains(filter.phrase)
    }
    
    func filterMessage(message: SMSMessage) -> ILMessageFilterAction {
        for filter in filters {
            if(applyFilter(filter: filter, message: message)) {
                switch (filter.action) {
                    case .junk: return ILMessageFilterAction.junk
                    case .promotion: return ILMessageFilterAction.promotion
                    case .transaction: return ILMessageFilterAction.transaction
                }
            }
        }
        return ILMessageFilterAction.none
    }

}
