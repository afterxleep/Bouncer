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
    
    /// Hard cap on the text scanned per regex match. A catastrophic pattern
    /// has bounded cost when the input is bounded, and SMS bodies are well
    /// under this limit in practice. If a body exceeds the cap it is treated
    /// as a non-match for regex rules — which is the safe failure mode.
    static let maxRegexInputCharacters = 4096

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

        let bounded = String(text.prefix(SMSOfflineFilter.maxRegexInputCharacters))

        var compileOptions: NSRegularExpression.Options = []
        if !filter.caseSensitive {
            compileOptions.insert(.caseInsensitive)
        }
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: filter.phrase, options: compileOptions)
        } catch {
            os_log("FILTEREXTENSION - Invalid regex pattern: %@", log: OSLog.messageFilterLog, type: .error, filter.phrase)
            return false
        }

        if Self.containsNestedQuantifier(filter.phrase) {
            os_log("FILTEREXTENSION - Rejected pattern with nested quantifier: %@", log: OSLog.messageFilterLog, type: .error, filter.phrase)
            return false
        }

        let nsRange = NSRange(bounded.startIndex..., in: bounded)
        let didMatch = regex.firstMatch(in: bounded, options: [], range: nsRange) != nil

        os_log("FILTEREXTENSION - -- Match: %@", log: OSLog.messageFilterLog, type: .info, "\(didMatch)")
        os_log("FILTEREXTENSION - -- Method: Regex", log: OSLog.messageFilterLog, type: .info)
        return didMatch
    }
    
    func action(for filter: Filter) -> ILMessageFilterAction {
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
    
    func subAction(for filter: Filter) -> ILMessageFilterSubAction {
        switch filter.subAction {
        case .transactionOrder:
            return .transactionalOrders
        case .transactionFinance:
            return .transactionalFinance
        case .transactionReminders:
            return .transactionalReminders
        case .transactionHealth:
            return .transactionalHealth
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
    
    /// The first rule that matches, in evaluation order: allow rules win over
    /// block rules. Exposed separately from `filterMessage` so the extension can
    /// record which rule fired without re-running the match.
    func matchingFilter(message: SMSMessage) -> Filter? {
        os_log("FILTEREXTENSION - Message Received: %@", log: OSLog.messageFilterLog, type: .info, "\(message)")

        // Allow List filters first
        for filter in filters.allowList() {
            if applyFilter(filter: filter, message: message) { return filter }
        }

        // Block List filters if nothing found
        for filter in filters.blockList() {
            if applyFilter(filter: filter, message: message) { return filter }
        }
        return nil
    }

    func filterMessage(message: SMSMessage) -> SMSOfflineFilterResponse  {
        guard let filter = matchingFilter(message: message) else { return (.none, .none) }
        return (action(for: filter), subAction(for: filter))
    }

    /// Structural detection of a nested-quantifier pattern: a group whose body
    /// already contains a quantifier and which is itself quantified. That is
    /// the shape of `(a+)+`, `(.*)+`, `(\d{1,9})+` — the canonical catastrophic
    /// backtracking trap.
    ///
    /// Tokenised by hand so the check itself never depends on running a regex:
    /// a guard for a regex bug cannot itself be implemented in terms of regex.
    /// Respects backslash escapes and `[...]` character classes, and does not
    /// mistake `?` in `(?:`/`?P<name>` group headers for a quantifier.
    static func containsNestedQuantifier(_ pattern: String) -> Bool {
        let chars = Array(pattern)
        var index = 0
        var inCharClass = false
        var escaped = false
        var parenDepth = 0
        // For each open paren, whether the body seen so far contained a quantifier.
        var bodyHadQuantifier: [Bool] = []
        // One-shot: set true on a `)` whose group had a quantifier inside, and
        // cleared the moment any non-quantifier token is consumed. Prevents the
        // stuck-flag bug where a later unrelated quantifier would trigger.
        var pendingPostCloseQuantifier = false

        while index < chars.count {
            let ch = chars[index]
            if escaped {
                escaped = false
                pendingPostCloseQuantifier = false
                index += 1
                continue
            }
            if ch == "\\" {
                escaped = true
                pendingPostCloseQuantifier = false
                index += 1
                continue
            }
            if inCharClass {
                if ch == "]" { inCharClass = false }
                pendingPostCloseQuantifier = false
                index += 1
                continue
            }
            switch ch {
            case "[":
                inCharClass = true
                pendingPostCloseQuantifier = false
                index += 1
            case "(":
                let nextIdx = index + 1
                if nextIdx < chars.count, chars[nextIdx] == "?" {
                    let markerIdx = index + 2
                    if markerIdx < chars.count {
                        let marker = chars[markerIdx]
                        switch marker {
                        case ":", "=", "!", ">":
                            // (?:) (?=) (?!) (?>) — single-char group header.
                            index = index + 3
                        case "<":
                            // (?<name> — skip up to and including the closing `>`.
                            var j = index + 3
                            while j < chars.count && chars[j] != ">" { j += 1 }
                            if j < chars.count { j += 1 }
                            index = j
                        case "P":
                            // (?P<name> — Python named group.
                            var j = index + 3
                            while j < chars.count && chars[j] != ">" { j += 1 }
                            if j < chars.count { j += 1 }
                            index = j
                        default:
                            // Unrecognised (?...) form (e.g. (?imsx) flags or
                            // (?#comment)). Consume up to the matching close
                            // paren and don't push a frame — the body isn't
                            // real regex tokens, so it can't contain a
                            // catastrophic quantifier nesting.
                            var j = index + 2
                            var depth = 0
                            while j < chars.count {
                                if chars[j] == "(" { depth += 1 }
                                else if chars[j] == ")" {
                                    if depth == 0 { j += 1; break }
                                    depth -= 1
                                }
                                j += 1
                            }
                            pendingPostCloseQuantifier = false
                            index = j
                            continue
                        }
                    } else {
                        index = nextIdx
                    }
                } else {
                    index += 1
                }
                bodyHadQuantifier.append(false)
                parenDepth += 1
                pendingPostCloseQuantifier = false
            case ")":
                if parenDepth > 0 {
                    let insideHadQuantifier = bodyHadQuantifier.removeLast()
                    parenDepth -= 1
                    if parenDepth > 0 {
                        bodyHadQuantifier[parenDepth - 1] = bodyHadQuantifier[parenDepth - 1] || insideHadQuantifier
                    }
                    pendingPostCloseQuantifier = insideHadQuantifier
                } else {
                    pendingPostCloseQuantifier = false
                }
                index += 1
            case "*", "+":
                if pendingPostCloseQuantifier { return true }
                if parenDepth > 0 {
                    bodyHadQuantifier[parenDepth - 1] = true
                }
                pendingPostCloseQuantifier = false
                index += 1
            case "?":
                // `?` after an atom is a 0-or-1 quantifier. `?` immediately
                // after `(` was already handled as a group-header marker.
                if parenDepth > 0 {
                    bodyHadQuantifier[parenDepth - 1] = true
                }
                pendingPostCloseQuantifier = false
                index += 1
            case "{":
                var sawDigits = false
                var j = index + 1
                while j < chars.count {
                    let c = chars[j]
                    if c.isNumber || c == "," { sawDigits = true; j += 1 } else { break }
                }
                if sawDigits {
                    if pendingPostCloseQuantifier { return true }
                    if parenDepth > 0 {
                        bodyHadQuantifier[parenDepth - 1] = true
                    }
                }
                pendingPostCloseQuantifier = false
                index = j
            default:
                pendingPostCloseQuantifier = false
                index += 1
            }
        }
        _ = bodyHadQuantifier
        return false
    }
}
