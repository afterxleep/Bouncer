//
//  SpyAnalyticsTracker.swift
//  BouncerTests
//

import Foundation
@testable import Bouncer

/// Records what the app asked to send. Tests run on the main thread, so no locking.
final class SpyAnalyticsTracker: AnalyticsTracking {
    private(set) var events: [AnalyticsEvent] = []
    private(set) var registered: [AnalyticsProperties] = []
    private(set) var collectionStates: [Bool] = []

    var names: [String] { events.map(\.name) }

    func track(_ event: AnalyticsEvent) { events.append(event) }
    func register(_ properties: AnalyticsProperties) { registered.append(properties) }
    func setCollectionEnabled(_ enabled: Bool) { collectionStates.append(enabled) }

    func events(named name: String) -> [AnalyticsEvent] {
        events.filter { $0.name == name }
    }
}
