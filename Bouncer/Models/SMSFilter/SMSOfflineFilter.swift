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

    private func isUnsafeRegexPattern(_ pattern: String) -> Bool {
        // Check for common dangerous patterns
        let dangerousPatterns = [
            // Nested quantifiers
            ".*.*", ".+.+", "(a+)+", "(a*)*", "(a?)?+", "((a+)?)+",
            // Overlapping patterns with quantifiers
            "(a|a)+", "(a|aa)+",
            // Recursive patterns
            "(?R)", "(?0)"
        ]
        
        // Check if pattern contains any dangerous constructs
        if dangerousPatterns.contains(where: { pattern.contains($0) }) {
            return true
        }
        
        // Check for excessive quantifiers
        let quantifierPattern = "\\{\\d+,?\\d*\\}"
        if let regex = try? NSRegularExpression(pattern: quantifierPattern) {
            let matches = regex.matches(in: pattern, range: NSRange(pattern.startIndex..., in: pattern))
            for match in matches {
                let range = Range(match.range, in: pattern)!
                let quantifier = pattern[range]
                // Convert the quantifier range to string and split by comma
                let quantifierStr = String(quantifier)
                let numbers = quantifierStr.dropFirst().dropLast().split(separator: ",")
                
                // Parse the first number (minimum)
                guard let firstNumber = Int(String(numbers[0])) else {
                    return true // Invalid number format
                }
                
                // If there's a second number (maximum), parse it
                let secondNumber: Int?
                if numbers.count > 1 {
                    secondNumber = Int(String(numbers[1]))
                } else {
                    secondNumber = nil
                }
                
                // Check if either number exceeds our limit
                if firstNumber > 10000 || (secondNumber ?? 0) > 10000 {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func matchRegex(text: String, filter: Filter) -> Bool {
        // Handle empty text or filter phrase
        if text.isEmpty || filter.phrase.isEmpty {
            return false
        }
        
        // Validate regex pattern
        if isUnsafeRegexPattern(filter.phrase) {
            os_log("FILTEREXTENSION - Unsafe regex pattern detected: %@", log: OSLog.messageFilterLog, type: .error, filter.phrase)
            return false
        }
        
        // Try creating the regex first to validate it
        do {
            _ = try NSRegularExpression(pattern: filter.phrase)
        } catch {
            os_log("FILTEREXTENSION - Invalid regex pattern: %@", log: OSLog.messageFilterLog, type: .error, filter.phrase)
            return false
        }
        
        // Set a reasonable timeout for regex matching
        let timeout = DispatchTime.now() + .milliseconds(100)
        var result = false
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .userInitiated).async {
            var matchOptions: String.CompareOptions = [.regularExpression]
            if !filter.caseSensitive {
                matchOptions.insert(.caseInsensitive)
            }
            result = (text.range(of: filter.phrase, options: matchOptions) != nil)
            group.leave()
        }
        
        // Wait with timeout
        if group.wait(timeout: timeout) == .timedOut {
            os_log("FILTEREXTENSION - Regex matching timed out for pattern: %@", log: OSLog.messageFilterLog, type: .error, filter.phrase)
            return false
        }
        
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

