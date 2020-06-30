//
//  FilterServiceWordList.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class SMSFilterLocal {
        
    let filterListService: FilterFileStore = FilterFileStore()
    
    var filters: [Filter] = []
    
    //MARK: - Initializer
    init() {
        filterListService.migrateFromV1()
        self.filters = filterListService.filters
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
        return (filter.exactMatch) ? txt == filter.phrase : txt.contains(filter.phrase)
    }
    
    func isValidMessage(message: SMSMessage) -> Bool {
        for filter in filters {
            if(applyFilter(filter: filter, message: message)) {
                return true
            }
        }
        return false
        
    }

}
