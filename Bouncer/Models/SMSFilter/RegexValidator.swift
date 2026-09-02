//
//  RegexValidator.swift
//  Bouncer
//

import Foundation

/// Result of validating a user-entered regular-expression phrase.
///
/// The editor calls this before saving a regex rule. An invalid pattern must
/// not be saved, and the editor surfaces the message so the user knows why.
enum RegexValidator {

    enum Result: Equatable {
        case valid
        case invalid(String)
    }

    /// Placeholder implementation. The real rule-based detection (nested
    /// quantifiers, unclosed groups) is added as part of fixing the ReDoS
    /// guard, so the same module owns compile-validation and safety validation.
    static func validate(_ pattern: String) -> Result {
        if pattern.isEmpty { return .invalid("Regular expression cannot be empty") }
        do {
            _ = try NSRegularExpression(pattern: pattern)
            return .valid
        } catch {
            return .invalid(humanReadable(error: error, pattern: pattern))
        }
    }

    private static func humanReadable(error: Error, pattern: String) -> String {
        let nsError = error as NSError
        let detail = nsError.localizedDescription
        return "“\(pattern)” is not a valid regular expression. \(detail)"
    }
}
