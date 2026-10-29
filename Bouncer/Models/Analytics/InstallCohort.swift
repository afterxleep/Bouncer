//
//  InstallCohort.swift
//  Bouncer
//

import Foundation

enum InstallType: String {
    /// First ever launch happened on a build that has analytics.
    case newInstall = "new_install"
    /// Already had the app before analytics shipped.
    case existingUser = "existing_user"
}

/// Where a user is in their relationship with the app.
enum UserStage: String {
    case firstLaunch = "first_launch"
    case newUser = "new_user"
    case returning
}

struct InstallCohort: Equatable {
    let installType: InstallType
    let firstSeenAt: Date

    /// New installs stay "new" for their first week; everyone else, including
    /// people who had the app before analytics, is returning.
    static let newUserWindowDays = 7

    func daysSinceFirstSeen(now: Date, calendar: Calendar = .current) -> Int {
        let days = calendar.dateComponents([.day], from: firstSeenAt, to: now).day ?? 0
        return max(days, 0)
    }

    func stage(launchNumber: Int, now: Date, calendar: Calendar = .current) -> UserStage {
        guard installType == .newInstall else { return .returning }
        if launchNumber <= 1 { return .firstLaunch }
        return daysSinceFirstSeen(now: now, calendar: calendar) < Self.newUserWindowDays ? .newUser : .returning
    }
}

/// Decides once, and remembers, whether this install predates analytics.
///
/// Launch counts and the onboarding flag already exist from before analytics
/// shipped, so the first resolve can tell a fresh install (neither set) from an
/// upgrade (at least one set). The verdict is persisted because those values
/// change as soon as the app is used.
struct InstallCohortStore {
    private enum Keys {
        static let installType = "analyticsInstallType"
        static let firstSeenAt = "analyticsFirstSeenAt"
    }

    let userDefaults: UserDefaults

    func resolve(numberOfLaunches: Int, hasLaunchedApp: Bool, now: Date) -> InstallCohort {
        if let raw = userDefaults.string(forKey: Keys.installType),
           let installType = InstallType(rawValue: raw),
           let seconds = userDefaults.object(forKey: Keys.firstSeenAt) as? TimeInterval {
            return InstallCohort(installType: installType, firstSeenAt: Date(timeIntervalSince1970: seconds))
        }

        let installType: InstallType = (numberOfLaunches == 0 && !hasLaunchedApp) ? .newInstall : .existingUser
        userDefaults.set(installType.rawValue, forKey: Keys.installType)
        userDefaults.set(now.timeIntervalSince1970, forKey: Keys.firstSeenAt)
        return InstallCohort(installType: installType, firstSeenAt: now)
    }
}
