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
    
    private func applyFilter(filter: Filter, message: SMSMessage) -> Bool {
        var txt = ""
        switch (filter.type) {
            case .sender:
                txt = message.sender
            case .message:
                txt = message.text
            default:
                txt = "\(message.sender) \(message.text)"
        }

        return txt.lowercased().contains(filter.phrase.lowercased()) || (txt.range(of: filter.phrase, options:[.regularExpression, .caseInsensitive]) != nil)
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
