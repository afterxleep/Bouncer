//
//  MessageFilterExtension.swift
//  smsfilter
//
//  Created by Daniel Bernal on 3/9/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import IdentityLookup

class MessageFilterExtension: ILMessageFilterExtension {
    let filterService: FilterService = FilterWordListService()
}


extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        
        // First, check whether to filter using offline data (if possible).
        let offlineAction = self.offlineAction(for: queryRequest)
        
        switch offlineAction {
        case .none, .allow, .filter:
            let response = ILMessageFilterQueryResponse()
            response.action = offlineAction
            completion(response)
        @unknown default:
            print("Unknown handled case")
        }
    }
    
    private func offlineAction(for queryRequest: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        
        guard let messageBody = queryRequest.messageBody else { return .none }
        if(filterService.isValidMessage(message: messageBody)) {
            return .allow
        }
        return .filter
    }
    
    private func action(for networkResponse: ILNetworkResponse) -> ILMessageFilterAction {
        // Replace with logic to parse the HTTP response and data payload of `networkResponse` to return an action.
        return .none
    }
    
}
