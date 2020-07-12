//
//  RatingService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/11/20.
//

import Foundation

protocol RatingService {
    
    var launchesRequired: Int { get }
    var userSettings: UserSettings { get }
    
    func requestReview()
}
