//
//  AnalyticsTracking.swift
//  Bouncer
//

import SwiftUI

/// The app's single seam to an analytics backend.
protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)

    /// Properties attached to every later event until replaced. Used for what
    /// describes the user rather than the moment: install type, rule count.
    func register(_ properties: AnalyticsProperties)

    /// Starts or stops collection and, when stopping, forgets the anonymous
    /// identity and registered properties.
    func setCollectionEnabled(_ enabled: Bool)
}

/// Used by previews and tests that don't care about analytics.
struct NoOpAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {}
    func register(_ properties: AnalyticsProperties) {}
    func setCollectionEnabled(_ enabled: Bool) {}
}

/// Drops events and properties unless the user has said yes, checked on every
/// call so a change in Help takes effect immediately.
struct ConsentGatedAnalyticsTracker: AnalyticsTracking {
    let wrapped: AnalyticsTracking
    let isGranted: () -> Bool

    func track(_ event: AnalyticsEvent) {
        guard isGranted() else { return }
        wrapped.track(event)
    }

    func register(_ properties: AnalyticsProperties) {
        guard isGranted() else { return }
        wrapped.register(properties)
    }

    func setCollectionEnabled(_ enabled: Bool) {
        wrapped.setCollectionEnabled(enabled)
    }
}

private struct AnalyticsTrackerKey: EnvironmentKey {
    static let defaultValue: AnalyticsTracking = NoOpAnalyticsTracker()
}

extension EnvironmentValues {
    var analytics: AnalyticsTracking {
        get { self[AnalyticsTrackerKey.self] }
        set { self[AnalyticsTrackerKey.self] = newValue }
    }
}
