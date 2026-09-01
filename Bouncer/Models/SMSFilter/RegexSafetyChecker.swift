//
//  RegexSafetyChecker.swift
//  Bouncer
//

import Foundation

/// Structural detection of regex patterns at high risk of catastrophic
/// backtracking.
///
/// The earlier guard compared the pattern against literal substrings like
/// `".*.*"`, which both missed real catastrophic patterns (`(win+)+!`) and
/// rejected legitimate ones (`win.*.*prize`). A literal substring cannot tell
/// a quantifier inside a group from a quantifier outside, so it cannot detect
/// nesting.
///
/// The approach here is structural and conservative: walk the pattern,
/// recognise groups (respecting `\\`-escapes and `[...]` character classes),
/// and flag any group whose body already contained a quantifier when that
/// group itself is quantified. That is the shape of the classic ReDoS trap
/// (`(a+)+`, `(.*)+`, `(.{1,10})*`), and the only patterns it flags.
///
/// Restricted to unambiguous quantifier tokens (`*`, `+`, `{n,m}`) so `?` in
/// `(?:` non-capturing groups, `?P<name>` named groups, and lookahead markers
/// are not mistaken for quantifiers.
enum RegexSafetyChecker {

    /// True when `pattern` contains a quantified group whose body contained a
    /// quantifier — i.e. nesting that has the shape of catastrophic backtracking.
    static func containsNestedQuantifier(_ pattern: String) -> Bool {
        var frames: [Frame] = []
        var lastClosedHadQuantifier = false

        for token in tokenize(pattern) {
            switch token {
            case .openParen:
                frames.append(Frame())
            case .closeParen:
                let bodyHadQuantifier: Bool
                if let frame = frames.popLast() {
                    bodyHadQuantifier = frame.bodyHadQuantifier
                } else {
                    bodyHadQuantifier = false
                }
                if !frames.isEmpty {
                    frames[frames.count - 1].bodyHadQuantifier =
                        frames[frames.count - 1].bodyHadQuantifier || bodyHadQuantifier
                }
                lastClosedHadQuantifier = bodyHadQuantifier
            case .quantifier:
                if lastClosedHadQuantifier {
                    return true
                }
                if let last = frames.last {
                    frames[frames.count - 1].bodyHadQuantifier = true
                    _ = last
                }
            }
        }
        return false
    }

    private struct Frame {
        var bodyHadQuantifier: Bool = false
    }

    private enum Token {
        case openParen
        case closeParen
        case quantifier
    }

    private static func tokenize(_ pattern: String) -> [Token] {
        var result: [Token] = []
        // Index-based access so we can look ahead without consuming.
        let characters = Array(pattern)
        var index = 0
        var inCharClass = false
        var escaped = false

        while index < characters.count {
            let ch = characters[index]
            if escaped {
                escaped = false
                index += 1
                continue
            }
            if ch == "\\" {
                escaped = true
                index += 1
                continue
            }
            if inCharClass {
                if ch == "]" { inCharClass = false }
                index += 1
                continue
            }
            switch ch {
            case "[":
                inCharClass = true
                index += 1
            case "(":
                // Skip group-syntax markers like `?:`, `?=`, `?!`, `?P<name>`.
                let nextIndex = index + 1
                if nextIndex < characters.count, characters[nextIndex] == "?" {
                    consumeGroupHeader(characters: characters, startIndex: nextIndex + 1, endIndex: &index)
                } else {
                    index += 1
                }
                result.append(.openParen)
            case ")":
                result.append(.closeParen)
                index += 1
            case "*", "+":
                result.append(.quantifier)
                index += 1
            case "{":
                var sawDigits = false
                var j = index + 1
                while j < characters.count {
                    let c = characters[j]
                    if c.isNumber || c == "," {
                        sawDigits = true
                        j += 1
                    } else {
                        break
                    }
                }
                if sawDigits {
                    result.append(.quantifier)
                }
                index = j
            default:
                index += 1
            }
        }
        return result
    }

    private static func consumeGroupHeader(characters: [Character],
                                           startIndex: Int,
                                           endIndex: inout Int) {
        var j = startIndex
        while j < characters.count {
            let ch = characters[j]
            if ch == ">" { j += 1; endIndex = j; return }
            if ch == "(" { endIndex = j; return }
            j += 1
        }
        endIndex = j
    }
}
