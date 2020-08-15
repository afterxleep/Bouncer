//
//  RatingService.swift
//  Bouncer
//


import Foundation

protocol ReviewService {

    var appSettings: AppSettingsStore { get }
    mutating func requestReview()

}
