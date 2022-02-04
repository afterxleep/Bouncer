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
        
        // Filters initially used both matchText and regex, so if the value is not assigned, use both
        guard let useRegex = filter.useRegex else {
            return matchText(text: txt, filter: filter) || matchRegex(text: txt, filter: filter)
        }
        
        // Use different filter strategies based on user selection
        if useRegex {
            return matchRegex(text: txt, filter: filter)
        }
        else {
            return matchText(text: txt, filter: filter)
        }
    }
    
    private func matchText(text: String, filter: Filter) -> Bool {
        return text.lowercased().contains(filter.phrase)
    }
    
    private func matchRegex(text: String, filter: Filter) -> Bool {
        return (text.range(of: filter.phrase, options:[.regularExpression, .caseInsensitive]) != nil)
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
