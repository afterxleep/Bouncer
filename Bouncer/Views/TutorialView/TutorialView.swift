//
//  TutorialView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

protocol TutorialView {
    var title:String? { get set }
    var introText:String? { get set }
    var buttonText:String? { get set }
    var settingsText:String? { get set }
    var msgsText:String? { get set }
    var spamText:String? { get set }
    var bouncerText:String? { get set }
}
