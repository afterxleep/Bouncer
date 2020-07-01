//
//  MessageFilterExtension.swift
//  smsfilter
//
//  Created by Daniel Bernal on 3/9/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import IdentityLookup

class MessageFilterExtension: ILMessageFilterExtension {
    let filterService: SMSFilterLocal = SMSFilterLocal()
}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        
        let offlineAction = self.offlineAction(for: queryRequest)
        let response = ILMessageFilterQueryResponse()
        response.action = offlineAction
        completion(response)
    }
    
    private func offlineAction(for queryRequest: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        guard let sender = queryRequest.sender else { return .none }
        guard let messageBody = queryRequest.messageBody else { return .none }
        let message = SMSMessage(sender: sender, text: messageBody)        
        return filterService.filterMessage(message: message)
    }
    
    private func action(for networkResponse: ILNetworkResponse) -> ILMessageFilterAction {
        return .none
    }
    
}
