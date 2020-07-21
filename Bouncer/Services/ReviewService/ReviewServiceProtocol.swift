//
//  RatingService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/11/20.
//

import Foundation

protocol ReviewServiceProtocol {
    
    var launchesRequired: Int { get }
    var userSettings: UserSettingsProtocol { get }
    
    func requestReview()
}
