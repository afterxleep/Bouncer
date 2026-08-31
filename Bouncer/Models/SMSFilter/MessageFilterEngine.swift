//
//  MessageFilterEngine.swift
//  Bouncer
//
//  Outcome-decision logic for the SMS Message Filter extension, lifted out
//  of MessageFilterExtension so it can be unit-tested without the
//  IdentityLookup runtime. The extension's handle(_:context:completion:) is
//  the wiring around this; the engine is what makes the verdict.
//

import Foundation

enum MessageFilterOutcome: Equatable {
    case allow
    case deny(action: FilterDestination, subAction: FilterDestination)
}

struct MessageFilterEngine {

    let filters: [Filter]

    func decide(sender: String?, messageBody: String?) -> MessageFilterOutcome {
        guard let sender = sender, let messageBody = messageBody else {
            return .allow
        }
        let engine = SMSOfflineFilter(filterList: filters)
        let message = SMSMessage(sender: sender, text: messageBody)
        guard let matched = engine.matchingFilter(message: message) else {
            return .allow
        }
        return .deny(action: matched.action,
                     subAction: matched.subAction)
    }
}
