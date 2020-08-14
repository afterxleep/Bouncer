//

import Foundation
import IdentityLookup
import Combine

final class SMSOfflineFilter {
        
    let filterStore: FilterStore
    var filters: [Filter] = []
    
    //MARK: - Initializer
    init(filterStore: FilterStore = FilterStoreFile()) {
        self.filterStore = filterStore
    }
    
    fileprivate func applyFilter(filter: Filter, message: SMSMessage) -> Bool {
        var txt = ""
        switch (filter.type) {
            case .sender:
                txt = message.sender.lowercased()
            case .message:
                txt = message.text.lowercased()
            default:
                txt = "\(message.sender.lowercased()) \(message.text.lowercased())"
        }
        return txt.contains(filter.phrase)
    }
    
    func filterMessage(message: SMSMessage) -> AnyPublisher<ILMessageFilterAction, Never> {

        return filterStore.fetch()
            .map { filters in
                for filter in filters {
                    if(self.applyFilter(filter: filter, message: message)) {
                        switch (filter.action) {
                            case .junk: return ILMessageFilterAction.junk
                            case .promotion: return ILMessageFilterAction.promotion
                            case .transaction: return ILMessageFilterAction.transaction
                        }
                    }
                }
                return ILMessageFilterAction.junk
            }
            .catch { (error: FilterStoreError) -> Just<ILMessageFilterAction> in
                return Just(ILMessageFilterAction.none)
            }   
            .eraseToAnyPublisher()

    }
}





