//
//  FilterServiceWordList.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import Combine

final class SMSFilterLocal {
        
    let filterListService: FilterFileStore = FilterFileStore()
    var cancellable: AnyCancellable?
    
    var filters: [Filter] = []
    
    //MARK: - Initializer
    init() {
        cancellable = filterListService
            .$filters
                .receive(on: RunLoop.main)
                .sink { [weak self] filters in
                    self?.filters = filters
                }
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
        var result = true
        for filter in filters {
            result = applyFilter(filter: filter, message: message)
        }
        return result
        
    }

}
