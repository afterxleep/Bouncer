//
//  MessageFilterExtension.swift
//  smsfilter
//

import IdentityLookup
import os.log
import Combine

final class MessageFilterExtension: ILMessageFilterExtension {

    var filters = [Filter]()
    var filterStore = FilterStoreFile()
    var cancellables = [AnyCancellable]()

    override init() {
        os_log("FILTEREXTENSION - Message filtering Started.", log: OSLog.messageFilterLog, type: .info)
        super.init()
    }

    deinit {
        os_log("FILTEREXTENSION - Message filtering complete.", log: OSLog.messageFilterLog, type: .info)
    }

    private func runFilters(_ queryRequest: ILMessageFilterQueryRequest,
                             context: ILMessageFilterExtensionContext,
                             completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let response = ILMessageFilterQueryResponse()
        guard let sender = queryRequest.sender, let messageBody = queryRequest.messageBody else {
            return
        }
        let engine = SMSOfflineFilter(filterList: filters)
        let message = SMSMessage(sender: sender, text: messageBody)

        if let matched = engine.matchingFilter(message: message) {
            response.action = engine.action(for: matched)
            response.subAction = engine.subAction(for: matched)
            // Record that this rule earned its place. Counts only — no part of
            // the message is written anywhere.
            RuleActivityStore.shared.record(match: matched.id)
        } else {
            response.action = .none
            response.subAction = .none
        }
        os_log("FILTEREXTENSION - Filtering action: %@", log: OSLog.messageFilterLog, type: .info, "\(response.action.rawValue)")
        os_log("FILTEREXTENSION - Filtering sub-action: %@", log: OSLog.messageFilterLog, type: .info, "\(response.subAction.rawValue)")
        os_log("FILTEREXTENSION - Filtering done", log: OSLog.messageFilterLog, type: .info)
        completion(response)
    }

}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {

        filterStore.fetch()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: {_ in
            }, receiveValue: { [weak self] result in
                os_log("FILTEREXTENSION - Filter list loaded", log: OSLog.messageFilterLog, type: .info)
                self?.filters = result
                return self?.runFilters(queryRequest, context: context, completion: completion) ?? ()
            })
            .store(in: &self.cancellables)
    }

}

extension MessageFilterExtension: ILMessageFilterCapabilitiesQueryHandling {
    
    func handle(_ capabilitiesQueryRequest: ILMessageFilterCapabilitiesQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterCapabilitiesQueryResponse) -> Void) {
        let response = ILMessageFilterCapabilitiesQueryResponse()
        response.transactionalSubActions = [.transactionalOrders,
                                            .transactionalOthers,
                                            .transactionalFinance,
                                            .transactionalReminders]
        response.promotionalSubActions = [.promotionalOffers,
                                          .promotionalCoupons,
                                          .promotionalOthers]
        completion(response)
    }
}

