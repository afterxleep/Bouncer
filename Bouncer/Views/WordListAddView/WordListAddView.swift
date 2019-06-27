//
//  WordListAddView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

protocol WordListAddView {
    var title:String? { get set }
    var noNotificationMsgText:String? { get set }
    var enterWordText:String? { get set }
    func addWord()
}
