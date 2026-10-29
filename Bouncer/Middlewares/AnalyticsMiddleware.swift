//
//  AnalyticsMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

/// What the middleware needs to know about this launch, fixed at startup.
struct AnalyticsLaunchContext: Equatable {
    let cohort: InstallCohort
    let launchNumber: Int
    let onboardingCompleted: Bool
    let appVersion: String
}

/// Reports what the store does — launches, rule changes, imports, failures —
/// without the views having to remember to. Events about taps that never reach
/// the store are sent from the views instead.
///
/// Rule events fire when the change is requested, not when the disk write
/// lands; a failed write is reported separately as an error event.
func analyticsMiddleware(tracker: AnalyticsTracking,
                         launch: AnalyticsLaunchContext,
                         now: @escaping () -> Date) -> Middleware<AppState, AppAction> {
    var launchReported = false
    var snapshotReported = false

    func registerProfile(rules: RuleLibraryStats) {
        let current = now()
        var profile: AnalyticsProperties = [
            "install_type": .string(launch.cohort.installType.rawValue),
            "user_stage": .string(launch.cohort.stage(launchNumber: launch.launchNumber, now: current).rawValue),
            "launch_count": .int(launch.launchNumber),
            "days_since_first_seen": .int(launch.cohort.daysSinceFirstSeen(now: current)),
            "app_version": .string(launch.appVersion),
        ]
        profile.merge(rules.properties) { $1 }
        tracker.register(profile)
    }

    func reportLaunchOnce() {
        guard !launchReported else { return }
        launchReported = true
        tracker.track(.appLaunched(
            launchNumber: launch.launchNumber,
            installType: launch.cohort.installType,
            daysSinceFirstSeen: launch.cohort.daysSinceFirstSeen(now: now()),
            onboardingCompleted: launch.onboardingCompleted
        ))
    }

    return { state, action in
        switch action {

        case .settings(action: .appLaunched):
            guard state.settings.analyticsConsent.isGranted else { break }
            registerProfile(rules: RuleLibraryStats(filters: state.filters.filters))
            reportLaunchOnce()

        case .settings(action: .setAnalyticsConsent(let consent)):
            tracker.setCollectionEnabled(consent.isGranted)
            guard consent.isGranted else { break }
            let stats = RuleLibraryStats(filters: state.filters.filters)
            registerProfile(rules: stats)
            reportLaunchOnce()
            // The library finished loading while the sheet was up, so nothing
            // else will report it this session.
            if !snapshotReported {
                snapshotReported = true
                tracker.track(.ruleLibrarySnapshot(stats))
            }

        case .filter(action: .fetchComplete(let filters)):
            let stats = RuleLibraryStats(filters: filters)
            registerProfile(rules: stats)
            if launchReported, !snapshotReported {
                snapshotReported = true
                tracker.track(.ruleLibrarySnapshot(stats))
            }

        case .filter(action: .add(let filter)):
            tracker.track(.ruleCreated(filter, ruleCountAfter: state.filters.filters.count + 1))

        case .filter(action: .update(let filter)):
            tracker.track(.ruleUpdated(filter))

        case .filter(action: .delete(let id)):
            if let filter = state.filters.filters.first(where: { $0.id == id }) {
                tracker.track(.ruleDeleted(filter, ruleCountAfter: state.filters.filters.count - 1))
            }

        case .filter(action: .addMany(let filters)):
            tracker.track(.rulesImported(RuleLibraryStats(filters: filters)))

        case .filter(action: .decodeComplete(let filters)):
            let known = Set(state.filters.filters)
            tracker.track(.importFileParsed(ruleCount: filters.count,
                                            newRuleCount: filters.filter { !known.contains($0) }.count))

        case .filter(action: .fetchError), .filter(action: .addError), .filter(action: .addManyError),
             .filter(action: .updateError), .filter(action: .deleteError), .filter(action: .error):
            if let error = state.filters.filterError {
                tracker.track(.errorShown(kind: error.analyticsKind))
            }

        default:
            break
        }
        return Empty().eraseToAnyPublisher()
    }
}
