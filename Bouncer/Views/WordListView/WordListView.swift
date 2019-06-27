//
//  WordListView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import UIKit

protocol WordListView {
    var title:String? { get set }
    var removeButtonText:String? { get set }
    var removeButtonBgColor: UIColor? { get set }
}
