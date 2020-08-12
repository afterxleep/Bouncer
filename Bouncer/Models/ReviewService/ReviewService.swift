//
//  RatingService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/11/20.
//

import Foundation

protocol ReviewService {
    
    var launchesRequired: Int { get }
    var appSettings: AppSettingsStore { get }
    
    func requestReview()
}
