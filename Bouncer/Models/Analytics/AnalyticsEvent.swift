//
//  AnalyticsEvent.swift
//  Bouncer
//

import Foundation

// MARK: - Property values

/// The only value shapes an event may carry. Free-form `Any` would let a rule
/// phrase or message body slip into an event by accident; a closed set makes
/// that a compile error.
enum AnalyticsValue: Equatable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    case string(String)
    case int(Int)
    case bool(Bool)

    init(stringLiteral value: String) { self = .string(value) }
    init(integerLiteral value: Int) { self = .int(value) }
    init(booleanLiteral value: Bool) { self = .bool(value) }

    var sdkValue: Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .bool(let value): return value
        }
    }
}

typealias AnalyticsProperties = [String: AnalyticsValue]

extension Dictionary where Key == String, Value == AnalyticsValue {
    var sdkRepresentation: [String: Any] { mapValues(\.sdkValue) }
}

// MARK: - Shared vocabulary

enum OnboardingMode: String {
    case firstRun = "first_run"
    case help
}

/// Where in the app an action started.
enum AnalyticsEntryPoint: String {
    case toolbar
    case emptyState = "empty_state"
    case libraryMenu = "library_menu"
    case onboarding
    case help
    case privacySheet = "privacy_sheet"
}

enum RuleEditorMode: String {
    case add
    case edit
}

enum RuleDeleteMethod: String {
    case swipe
    case contextMenu = "context_menu"
}

enum RuleOption: String {
    case regex
    case caseSensitive = "case_sensitive"
}

enum ImportSelectionMode: String {
    case all
    case new
    case none
}

enum HelpAction: String {
    case openSettings = "open_settings"
    case walkthrough
    case emailSupport = "email_support"
}

// MARK: - Rule descriptions

extension Filter {

    /// Describes a rule's shape without its text. The phrase is the one thing
    /// that can identify a person — a contact's name, a bank — so only its
    /// length leaves the device.
    var analyticsProperties: AnalyticsProperties {
        [
            "action": .string(action.rawValue),
            "destination": .string(analyticsDestination),
            "lane": .string(RuleScope(destination: action).rawValue),
            "match_type": .string(type.rawValue),
            "uses_regex": .bool(useRegex),
            "case_sensitive": .bool(caseSensitive),
            "phrase_length": .int(phrase.count),
        ]
    }

    /// The most specific destination: the sub-category when there is one.
    var analyticsDestination: String {
        subAction == .none ? action.rawValue : subAction.rawValue
    }
}

/// Counts that describe a whole rule library.
struct RuleLibraryStats: Equatable {
    let total: Int
    let allow: Int
    let junk: Int
    let categories: Int
    let regex: Int
    let caseSensitive: Int

    init(filters: [Filter]) {
        total = filters.count
        allow = filters.filter { RuleScope.allow.contains($0) }.count
        junk = filters.filter { RuleScope.junk.contains($0) }.count
        categories = filters.filter { RuleScope.categories.contains($0) }.count
        regex = filters.filter(\.useRegex).count
        caseSensitive = filters.filter(\.caseSensitive).count
    }

    var properties: AnalyticsProperties {
        [
            "rule_count": .int(total),
            "allow_rule_count": .int(allow),
            "junk_rule_count": .int(junk),
            "category_rule_count": .int(categories),
            "regex_rule_count": .int(regex),
            "case_sensitive_rule_count": .int(caseSensitive),
        ]
    }
}

extension FilterError {

    /// A stable label that carries no message text: error messages can embed
    /// the user's own phrase or a file path.
    var analyticsKind: String {
        switch self {
        case .emptyImportFileError: return "empty_import_file"
        case .decodingFailed: return "decoding_failed"
        case .loadFailed: return "load_failed"
        case .saveFailed: return "save_failed"
        case .deleteFailed: return "delete_failed"
        case .diskError: return "disk_error"
        case .invalidRegex: return "invalid_regex"
        case .duplicateRule: return "duplicate_rule"
        }
    }
}

// MARK: - Events

/// Every event the app can send. Names and property keys live here and nowhere
/// else, so the taxonomy can be read, reviewed, and tested in one place.
enum AnalyticsEvent: Equatable {

    // Lifecycle
    case appLaunched(launchNumber: Int, installType: InstallType, daysSinceFirstSeen: Int, onboardingCompleted: Bool)
    case ruleLibrarySnapshot(RuleLibraryStats)
    case privacyChoiceMade(AnalyticsConsent, source: AnalyticsEntryPoint)

    // Onboarding
    case onboardingStarted
    case onboardingStepViewed(step: Int, mode: OnboardingMode)
    case onboardingBackTapped(fromStep: Int)
    case onboardingSettingsOpened(step: Int)
    case onboardingSkipped
    case onboardingCompleted(mode: OnboardingMode)
    case onboardingClosed(step: Int)
    case supportRequested(source: AnalyticsEntryPoint, mailAvailable: Bool)

    // Rule library
    case ruleLaneChanged(lane: RuleScope, laneRuleCount: Int)
    case ruleSearchStarted(lane: RuleScope)
    case addRuleTapped(source: AnalyticsEntryPoint, lane: RuleScope)
    case ruleOpened(Filter)
    case ruleDeleteTapped(RuleDeleteMethod)
    case helpOpened(source: AnalyticsEntryPoint)
    case helpActionTapped(HelpAction)

    // Rule editor
    case ruleEditorOpened(RuleEditorMode)
    case ruleEditorCancelled
    case ruleCategoryPickerOpened
    case ruleDestinationSelected(destination: String)
    case ruleOptionToggled(RuleOption, enabled: Bool)
    case ruleAdvancedToggled(expanded: Bool)
    case regexHelpOpened

    // Rule changes
    case ruleCreated(Filter, ruleCountAfter: Int)
    case ruleUpdated(Filter)
    case ruleDeleted(Filter, ruleCountAfter: Int)

    // Import
    case importStarted
    case importFileParsed(ruleCount: Int, newRuleCount: Int)
    case importSelectionChanged(ImportSelectionMode)
    case importCancelled
    case rulesImported(RuleLibraryStats)

    // Problems
    case errorShown(kind: String)

    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .ruleLibrarySnapshot: return "rule_library_snapshot"
        case .privacyChoiceMade: return "privacy_choice_made"
        case .onboardingStarted: return "onboarding_started"
        case .onboardingStepViewed: return "onboarding_step_viewed"
        case .onboardingBackTapped: return "onboarding_back_tapped"
        case .onboardingSettingsOpened: return "onboarding_settings_opened"
        case .onboardingSkipped: return "onboarding_skipped"
        case .onboardingCompleted: return "onboarding_completed"
        case .onboardingClosed: return "onboarding_closed"
        case .supportRequested: return "support_requested"
        case .ruleLaneChanged: return "rule_lane_changed"
        case .ruleSearchStarted: return "rule_search_started"
        case .addRuleTapped: return "add_rule_tapped"
        case .ruleOpened: return "rule_opened"
        case .ruleDeleteTapped: return "rule_delete_tapped"
        case .helpOpened: return "help_opened"
        case .helpActionTapped: return "help_action_tapped"
        case .ruleEditorOpened: return "rule_editor_opened"
        case .ruleEditorCancelled: return "rule_editor_cancelled"
        case .ruleCategoryPickerOpened: return "rule_category_picker_opened"
        case .ruleDestinationSelected: return "rule_destination_selected"
        case .ruleOptionToggled: return "rule_option_toggled"
        case .ruleAdvancedToggled: return "rule_advanced_toggled"
        case .regexHelpOpened: return "regex_help_opened"
        case .ruleCreated: return "rule_created"
        case .ruleUpdated: return "rule_updated"
        case .ruleDeleted: return "rule_deleted"
        case .importStarted: return "import_started"
        case .importFileParsed: return "import_file_parsed"
        case .importSelectionChanged: return "import_selection_changed"
        case .importCancelled: return "import_cancelled"
        case .rulesImported: return "rules_imported"
        case .errorShown: return "error_shown"
        }
    }

    var properties: AnalyticsProperties {
        switch self {
        case .appLaunched(let launchNumber, let installType, let days, let onboardingCompleted):
            return [
                "launch_number": .int(launchNumber),
                "is_first_launch": .bool(launchNumber == 1 && installType == .newInstall),
                "install_type": .string(installType.rawValue),
                "days_since_first_seen": .int(days),
                "onboarding_completed": .bool(onboardingCompleted),
            ]
        case .ruleLibrarySnapshot(let stats):
            return stats.properties
        case .privacyChoiceMade(let choice, let source):
            return ["choice": .string(choice.rawValue), "source": .string(source.rawValue)]
        case .onboardingStepViewed(let step, let mode):
            return ["step": .int(step), "mode": .string(mode.rawValue)]
        case .onboardingBackTapped(let step), .onboardingSettingsOpened(let step), .onboardingClosed(let step):
            return ["step": .int(step)]
        case .onboardingCompleted(let mode):
            return ["mode": .string(mode.rawValue)]
        case .supportRequested(let source, let mailAvailable):
            return ["source": .string(source.rawValue), "mail_available": .bool(mailAvailable)]
        case .ruleLaneChanged(let lane, let count):
            return ["lane": .string(lane.rawValue), "lane_rule_count": .int(count)]
        case .ruleSearchStarted(let lane):
            return ["lane": .string(lane.rawValue)]
        case .addRuleTapped(let source, let lane):
            return ["source": .string(source.rawValue), "lane": .string(lane.rawValue)]
        case .ruleOpened(let filter), .ruleUpdated(let filter):
            return filter.analyticsProperties
        case .ruleCreated(let filter, let count), .ruleDeleted(let filter, let count):
            return filter.analyticsProperties.merging(["rule_count_after": .int(count)]) { $1 }
        case .ruleDeleteTapped(let method):
            return ["method": .string(method.rawValue)]
        case .helpOpened(let source):
            return ["source": .string(source.rawValue)]
        case .helpActionTapped(let action):
            return ["action": .string(action.rawValue)]
        case .ruleEditorOpened(let mode):
            return ["mode": .string(mode.rawValue)]
        case .ruleDestinationSelected(let destination):
            return ["destination": .string(destination)]
        case .ruleOptionToggled(let option, let enabled):
            return ["option": .string(option.rawValue), "enabled": .bool(enabled)]
        case .ruleAdvancedToggled(let expanded):
            return ["expanded": .bool(expanded)]
        case .importFileParsed(let count, let newCount):
            return ["rule_count": .int(count), "new_rule_count": .int(newCount)]
        case .importSelectionChanged(let mode):
            return ["mode": .string(mode.rawValue)]
        case .rulesImported(let stats):
            return [
                "imported_count": .int(stats.total),
                "imported_allow_count": .int(stats.allow),
                "imported_junk_count": .int(stats.junk),
                "imported_category_count": .int(stats.categories),
            ]
        case .errorShown(let kind):
            return ["kind": .string(kind)]
        case .onboardingStarted, .onboardingSkipped, .ruleEditorCancelled, .ruleCategoryPickerOpened, .regexHelpOpened,
             .importStarted, .importCancelled:
            return [:]
        }
    }
}
