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
import IdentityLookup

struct MessageFilterEngine {

    let filters: [Filter]

    func decide(sender: String?, messageBody: String?) -> ILMessageFilterQueryResponse {
        let response = ILMessageFilterQueryResponse()
        guard let sender = sender, let messageBody = messageBody else {
            response.action = .none
            response.subAction = .none
            return response
        }
        let engine = SMSOfflineFilter(filterList: filters)
        let message = SMSMessage(sender: sender, text: messageBody)
        guard let matched = engine.matchingFilter(message: message) else {
            response.action = .none
            response.subAction = .none
            return response
        }
        response.action = engine.action(for: matched)
        response.subAction = engine.subAction(for: matched)
        return response
    }
}
