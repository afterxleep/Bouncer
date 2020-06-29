//
//  FilterServiceWordList.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class SMSFilterLocal: SMSFilter {
    func isValidMessage(sender: String?, message: String?) -> Bool {
        return true
    }
    
    
    /*
    private let filterStore: FilterStore
        
    init(filterStore: FilterStore = FilterFileStoreService()) {
        self.filterStore = filterStore
    }
    
    func isValidMessage(sender: String?, message: String?) -> Bool {
        /*
        guard let sender = sender?.lowercased() else { return false }
        guard let messageBody = message?.lowercased() else { return false }        
        let wordList = filterStore.read()
        
        for filter in wordList {
            //if sender.contains(filter..lowercased()) || messageBody.contains(word.lowercased()) {
                //return false
            //}
        }
         */
        
        return true
    }
 */
}
