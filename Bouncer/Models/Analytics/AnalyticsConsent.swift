//
//  AnalyticsConsent.swift
//  Bouncer
//

import Foundation

/// The user's answer to "may Bouncer count what you do in the app?".
/// Nothing is collected until this is `.granted`; `.unknown` means the question
/// hasn't been asked yet and is what triggers the privacy sheet.
enum AnalyticsConsent: String {
    case unknown
    case granted
    case denied

    var isGranted: Bool { self == .granted }
}
