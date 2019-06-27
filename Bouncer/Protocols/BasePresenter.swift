//
//  BasePresenter.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import UIKit

protocol BasePresenter {
    
    associatedtype View
    
    func attachView(view: View)
    func detachView()
    func destroy()
    
}

extension BasePresenter {
    func localizationFor(key: String) -> String? {
        return NSLocalizedString(key, comment: "")
    }
}
