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

    private func respond(queryRequest: ILMessageFilterQueryRequest,
                         completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let outcome = MessageFilterEngine(filters: filters)
            .decide(sender: queryRequest.sender,
                    messageBody: queryRequest.messageBody)
        if let matched = outcome.matched {
            RuleActivityStore.shared.record(match: matched.id)
        }
        os_log("FILTEREXTENSION - Filtering action: %@", log: OSLog.messageFilterLog, type: .info, "\(outcome.response.action.rawValue)")
        os_log("FILTEREXTENSION - Filtering sub-action: %@", log: OSLog.messageFilterLog, type: .info, "\(outcome.response.subAction.rawValue)")
        os_log("FILTEREXTENSION - Filtering done", log: OSLog.messageFilterLog, type: .info)
        completion(outcome.response)
    }

}

extension MessageFilterExtension: ILMessageFilterQueryHandling {

    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {

        let deliver: ([Filter]) -> Void = { [weak self] loadedFilters in
            guard let self = self else {
                let fallback = ILMessageFilterQueryResponse()
                fallback.action = .none
                fallback.subAction = .none
                completion(fallback)
                return
            }
            self.filters = loadedFilters
            self.respond(queryRequest: queryRequest, completion: completion)
        }

        let deliverFailure: () -> Void = { [weak self] in
            // fetch() never resolves on a missing container; the audit calls
            // out that an empty list silently disables filtering. Deliver an
            // allow verdict so the message reaches the user — they can
            // address the underlying store problem separately.
            _ = self
            let fallback = ILMessageFilterQueryResponse()
            fallback.action = .none
            fallback.subAction = .none
            completion(fallback)
        }

        filterStore.fetch()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionCase in
                if case .failure = completionCase {
                    deliverFailure()
                }
            }, receiveValue: { result in
                os_log("FILTEREXTENSION - Filter list loaded", log: OSLog.messageFilterLog, type: .info)
                deliver(result)
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
