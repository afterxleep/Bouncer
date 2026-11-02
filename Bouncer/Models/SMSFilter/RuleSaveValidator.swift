//
//  RuleSaveValidator.swift
//  Bouncer
//

import Foundation

/// The save-time validation logic for a rule. Lives outside the view so it can
/// be unit-tested without driving a SwiftUI view.
///
/// Returns `.accept(Filter)` when the rule is safe to save, and `.reject(String)`
/// with a user-readable reason otherwise. The view routes `.reject` through the
/// existing `FilterError.invalidRegex` alert path.
enum RuleSaveValidator {

    enum Outcome: Equatable {
        case accept(Filter)
        case reject(String)
        /// Another rule already does exactly this; saving would only add a
        /// second row that can never change an outcome.
        case duplicate
    }

    /// Build a rule from the editor's bound state, applying any save-time
    /// validation. Callers pass `useRegex: true` when the user has flipped the
    /// regular-expression toggle on; the validator rejects uncompilable
    /// patterns in that case.
    static func makeRule(id: UUID?,
                         phrase: String,
                         type: FilterType,
                         destination: FilterDestination,
                         useRegex: Bool,
                         existing: [Filter] = []) -> Outcome {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .reject("The phrase cannot be empty.")
        }
        if useRegex {
            switch RegexValidator.validate(trimmed) {
            case .valid:
                break
            case .invalid(let message):
                return .reject(message)
            }
            if SMSOfflineFilter.containsNestedQuantifier(trimmed) {
                return .reject("“\(trimmed)” has nested quantifiers and could hang the message filter.")
            }
        }
        let (action, subAction) = destination.split()
        let rule = Filter(id: id ?? UUID(),
                          phrase: trimmed,
                          type: type,
                          action: action,
                          subAction: subAction,
                          useRegex: useRegex,
                          caseSensitive: false)
        if existing.contains(where: { $0.duplicates(rule) }) {
            return .duplicate
        }
        return .accept(rule)
    }
}

private extension Filter {
    /// Same phrase (ignoring case), same place to look, same destination and
    /// matching mode — but a different rule, so editing a rule in place is fine.
    func duplicates(_ other: Filter) -> Bool {
        id != other.id
            && phrase.caseInsensitiveCompare(other.phrase) == .orderedSame
            && type == other.type
            && action == other.action
            && subAction == other.subAction
            && useRegex == other.useRegex
    }
}

private extension FilterDestination {
    /// Mirror of the same split in `FilterDetailContainerView.filterToSave`,
    /// kept here so the validator owns the full save contract.
    func split() -> (FilterDestination, FilterDestination) {
        switch self {
        case .promotion, .promotionOffers, .promotionCoupons, .promotionOther:
            return (.promotion, self)
        case .transaction, .transactionOrder, .transactionFinance,
             .transactionReminders, .transactionHealth, .transactionOther:
            return (.transaction, self)
        case .junk:
            return (.junk, .none)
        case .none:
            return (.none, .none)
        case .allow:
            return (.allow, .allow)
        }
    }
}
