//
//  FilterServiceWordList.swift
//  Bouncer
//

import Foundation
import IdentityLookup

final class SMSFilterLocal {
        
    let filterListStore: FilterStore
    
    var filters: [Filter] = []
    
    //MARK: - Initializer
    init(filterListStore: FilterStore = FilterStoreFile()) {
        self.filterListStore = filterListStore
        let _ = filterListStore.migrateFromV1()
        //self.filters = filterListStore.filters
        self.filters = []
    }
    
    func applyFilter(filter: Filter, message: SMSMessage) -> Bool {
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
    
    func filterMessage(message: SMSMessage) -> ILMessageFilterAction {
        for filter in filters {
            if(applyFilter(filter: filter, message: message)) {
                switch (filter.action) {
                    case .junk: return .junk
                    case .promotion: return .promotion
                    case .transaction: return .transaction
                }
            }
        }
        return .none
    }

}
