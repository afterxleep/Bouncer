//
//  SMSOfflineFilter.swift
//  Bouncer
//

import Foundation
import IdentityLookup
import OSLog

typealias SMSOfflineFilterResponse = (action: ILMessageFilterAction,
                                      subAction: ILMessageFilterSubAction)

struct SMSOfflineFilter {
    
    var filters: [Filter]
    
    //MARK: - Initializer
    init(filterList: [Filter]) {
        self.filters = filterList
    }
    
    private func applyFilter(filter: Filter, message: SMSMessage) -> Bool {
        os_log("FILTEREXTENSION - Applying filter: %@", log: OSLog.messageFilterLog, type: .info, "\(filter.phrase)")
        
        // Handle messages based on filter type
        switch (filter.type) {
            case .sender:
                // For sender, we always trim
                let txt = message.sender.trimmingCharacters(in: .whitespacesAndNewlines)
                if txt.isEmpty { return false }
                return filter.useRegex ? matchRegex(text: txt, filter: filter) : match(text: txt, filter: filter)
                
            case .message:
                // For message content, only trim if not using regex
                let txt = filter.useRegex ? message.text : message.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !filter.useRegex && txt.isEmpty { return false }
                return filter.useRegex ? matchRegex(text: txt, filter: filter) : match(text: txt, filter: filter)
                
            default:
                // For 'any' type, concatenate raw strings first
                let combined = "\(message.sender) \(message.text)"
                let txt = filter.useRegex ? combined : combined.trimmingCharacters(in: .whitespacesAndNewlines)
                if !filter.useRegex && txt.isEmpty { return false }
                return filter.useRegex ? matchRegex(text: txt, filter: filter) : match(text: txt, filter: filter)
        }
    }

    private func match(text: String, filter: Filter) -> Bool {
        var matchOptions: String.CompareOptions = []
        if !filter.caseSensitive {
            matchOptions.insert(.caseInsensitive)
        }
        // Text is already trimmed in applyFilter, only trim the filter phrase
        let trimmedPhrase = filter.phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = text.range(of: trimmedPhrase, options: matchOptions) != nil
        os_log("FILTEREXTENSION - -- Match: %@", log: OSLog.messageFilterLog, type: .info, "\(result)")
        os_log("FILTEREXTENSION - -- Method: Text", log: OSLog.messageFilterLog, type: .info)
        return result
    }

    private func matchRegex(text: String, filter: Filter) -> Bool {
        // Handle empty text or filter phrase
        if text.isEmpty || filter.phrase.isEmpty {
            return false
        }
        
        var matchOptions: String.CompareOptions = [.regularExpression]
        if !filter.caseSensitive {
            matchOptions.insert(.caseInsensitive)
        }
        // Text is already trimmed in applyFilter
        let result = (text.range(of: filter.phrase, options: matchOptions) != nil)
        os_log("FILTEREXTENSION - -- Match: %@", log: OSLog.messageFilterLog, type: .info, "\(result)")
        os_log("FILTEREXTENSION - -- Method: Regex", log: OSLog.messageFilterLog, type: .info)
        return result
    }
    
    private func getAction(_ filter: Filter) -> ILMessageFilterAction {
        switch filter.action {
        case .junk:
            return .junk
        case .allow:
            return .allow
        case .transaction:
            return .transaction
        case .promotion:
            return .promotion
        default:
            return .none
        }
    }
    
    private func getSubAction(_ filter: Filter) -> ILMessageFilterSubAction {
        switch filter.subAction {
        case .transactionOrder:
            return .transactionalOrders
        case .transactionFinance:
            return .transactionalFinance
        case .transactionReminders:
            return .transactionalReminders
        case .promotionOffers:
            return .promotionalOffers
        case .promotionCoupons:
            return .promotionalCoupons
        default:
            // If no subaction pressent just return the base groups
            switch filter.action {
            case .promotion:
                return .promotionalOthers
            case .transaction:
                return .transactionalOthers
            default:
                return .none
            }
        }
    }
    
    func filterMessage(message: SMSMessage) -> SMSOfflineFilterResponse  {
        os_log("FILTEREXTENSION - Message Received: %@", log: OSLog.messageFilterLog, type: .info, "\(message)")

        // Allow List filters first
        for filter in filters.allowList() {
            if(applyFilter(filter: filter, message: message)) {
                return (getAction(filter), getSubAction(filter))
            }
        }

        // Block List filters if nothing found
        for filter in filters.blockList() {
            if(applyFilter(filter: filter, message: message)) {
                return (getAction(filter), getSubAction(filter))
            }
        }
        return (.none, .none)
    }

}

