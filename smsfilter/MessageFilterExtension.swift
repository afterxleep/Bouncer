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
        print("FILTEREXTENSION - Message filtering Started.")
        super.init()
        migrateFromV1()
        fetchFilters()
    }

    deinit {
        print("FILTEREXTENSION - Message filtering complete")
    }

    func fetchFilters() {
        filterStore.fetch()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: {_ in
            }, receiveValue: { [weak self] result in
                print("FILTEREXTENSION - Filter list loaded")
                self?.filters = result
            })
            .store(in: &self.cancellables)
    }

    func migrateFromV1() {
        filterStore.migrateFromV1()
    }

}

extension MessageFilterExtension: ILMessageFilterQueryHandling {

    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {

        let response = ILMessageFilterQueryResponse()
        guard let sender = queryRequest.sender, let messageBody = queryRequest.messageBody  else {
            response.action = .none
            completion(response)
            return
        }
        let filter = SMSOfflineFilter(filterList: filters)
        response.action = filter.filterMessage(message: SMSMessage(sender: sender, text: messageBody))
        print("FILTEREXTENSION - Filtering done")
        completion(response)
    }
}
