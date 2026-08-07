//
//  RuleActivityStore.swift
//  Bouncer
//
//  What each rule has actually caught.
//
//  A rule list is a set of guesses until you can see which ones fire. The
//  filter extension records a hit every time a rule matches; the app reads that
//  back so a rule can show its work — and so a rule that has never matched can
//  say so instead of sitting there looking identical to one that catches
//  hundreds of messages a week.
//
//  Lives in the shared app group because the extension writes it and the app
//  reads it. Deliberately tiny: counts and day buckets, never message content.
//  Nothing about a message is stored, on device or anywhere else.
//

import Foundation
import os.log

/// A rule's record: how often it has fired, and when.
struct RuleActivity: Codable, Equatable {
    /// Every match ever, across all time.
    var total: Int = 0
    /// The most recent match.
    var lastMatch: Date?
    /// Matches per day, keyed by days-since-epoch as a string. Swift encodes
    /// dictionaries with non-string keys as a flat array, which makes the file
    /// unreadable and brittle to migrate — so the keys are strings on purpose.
    var days: [String: Int] = [:]

    static let historyLength = 30

    /// Matches in the last `historyLength` days, oldest first — the shape the
    /// sparkline draws.
    func history(endingOn today: Int) -> [Int] {
        ((today - Self.historyLength + 1)...today).map { days[String($0)] ?? 0 }
    }

    /// Matches inside the reporting window. Trimmed at read as well as at
    /// write: a rule that stops firing keeps its old buckets until it fires
    /// again, and counting those would quietly inflate the window.
    func recentTotal(endingOn today: Int = RuleActivityStore.dayIndex()) -> Int {
        days.reduce(0) { sum, entry in
            guard let day = Int(entry.key), day > today - Self.historyLength else { return sum }
            return sum + entry.value
        }
    }
}

/// The whole file: rule id → record.
struct RuleActivityLog: Codable, Equatable {
    /// Keyed by `UUID.uuidString` for the same reason as `days`.
    var rules: [String: RuleActivity] = [:]

    subscript(id: UUID) -> RuleActivity {
        get { rules[id.uuidString] ?? RuleActivity() }
        set { rules[id.uuidString] = newValue }
    }
}

// MARK: - Store

/// Reads and writes the activity log in the shared container.
///
/// Writes land via an atomic replace, so a half-written file can never be read.
/// The queue only serialises writes *within* a process; the app and the filter
/// extension are separate processes, so a simultaneous write from each can
/// still lose one side's change. That is an acceptable trade here — the file
/// holds counters, not anything the app depends on being exact — and the cost
/// of file coordination on every incoming message is not.
final class RuleActivityStore: @unchecked Sendable {

    static let shared = RuleActivityStore()

    static let fileName = "activity.json"
    static let groupContainer = "group.com.banshai.bouncer"

    private let queue = DispatchQueue(label: "studio.bouncer.activity")

    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupContainer)?
            .appendingPathComponent(fileName)
    }

    /// Today as a day index, so buckets don't depend on the device's calendar
    /// formatting or locale.
    static func dayIndex(for date: Date = Date()) -> Int {
        Int(date.timeIntervalSince1970 / 86_400)
    }

    // MARK: Reading

    /// What a read found. "Nothing there yet" and "there is something there we
    /// couldn't understand" have to be told apart: the first is safe to write
    /// over, the second is somebody else's data.
    private enum ReadOutcome {
        case log(RuleActivityLog)
        case absent
        case unreadable
    }

    func load() -> RuleActivityLog {
        queue.sync {
            if case .log(let log) = Self.read() { return log }
            return RuleActivityLog()
        }
    }

    private static func read() -> ReadOutcome {
        guard let url = fileURL else { return .unreadable }
        guard let data = try? Data(contentsOf: url) else { return .absent }
        guard let log = try? JSONDecoder().decode(RuleActivityLog.self, from: data) else {
            os_log("Rule activity file could not be decoded; leaving it alone",
                   type: .error)
            return .unreadable
        }
        return .log(log)
    }

    // MARK: Writing

    /// Note that `id` matched, now.
    ///
    /// Synchronous on purpose. The filter extension calls this and then hands
    /// its response straight back to iOS, which is free to tear the process
    /// down immediately; an async write simply never landed, so matches went
    /// uncounted. The work is a small read, a mutation and an atomic write.
    func record(match id: UUID, at date: Date = Date()) {
        queue.sync {
            var log: RuleActivityLog
            switch Self.read() {
            case .log(let existing): log = existing
            case .absent: log = RuleActivityLog()
            // Don't overwrite a file we failed to parse — a bad read would
            // otherwise wipe every rule's history.
            case .unreadable: return
            }

            let today = Self.dayIndex(for: date)
            var activity = log[id]
            activity.total += 1
            activity.lastMatch = date
            activity.days[String(today), default: 0] += 1
            activity.days = activity.days.filter { (Int($0.key) ?? 0) > today - RuleActivity.historyLength }
            log[id] = activity
            Self.write(log)
        }
    }

    /// Drop records for rules that no longer exist, so the file can't grow
    /// without bound as rules come and go.
    ///
    /// Never call this with an empty set — see `FilterListView.refreshActivity`.
    func prune(keeping ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        queue.async {
            guard case .log(var log) = Self.read() else { return }
            let before = log.rules.count
            let keep = Set(ids.map(\.uuidString))
            log.rules = log.rules.filter { keep.contains($0.key) }
            if log.rules.count != before { Self.write(log) }
        }
    }

    private static func write(_ log: RuleActivityLog) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(log) else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            os_log("Could not write rule activity: %{public}@",
                   type: .error, error.localizedDescription)
        }
    }
}
