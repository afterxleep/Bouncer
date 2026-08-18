//
//  OnboardingLocalizationTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

/// Guards the onboarding copy: every key the UI asks for must exist in every
/// shipped language, and the retired tutorial keys must stay gone.
final class OnboardingLocalizationTests: XCTestCase {

    private let languages = ["en", "es"]

    /// The bundle that carries the app's `.lproj` folders.
    private var appBundle: Bundle {
        Bundle(for: FilterStoreFile.self)
    }

    private func table(for language: String) throws -> [String: String] {
        let path = try XCTUnwrap(
            appBundle.path(forResource: language, ofType: "lproj"),
            "Missing \(language).lproj in the app bundle"
        )
        let bundle = try XCTUnwrap(Bundle(path: path))
        let stringsPath = try XCTUnwrap(
            bundle.path(forResource: "Localizable", ofType: "strings"),
            "Missing Localizable.strings for \(language)"
        )
        let contents = try XCTUnwrap(
            NSDictionary(contentsOfFile: stringsPath) as? [String: String],
            "Localizable.strings for \(language) is not a valid strings file"
        )
        return contents
    }

    /// Every key the onboarding UI references.
    private var requiredKeys: [String] {
        var keys = [
            "ONBOARDING_WELCOME_TITLE",
            "ONBOARDING_WELCOME_BODY",
            "ONBOARDING_BULLET_JUNK",
            "ONBOARDING_BULLET_ALLOW",
            "ONBOARDING_BULLET_CATEGORIES",
            "ONBOARDING_GET_STARTED",
            "ONBOARDING_SKIP",
            "ONBOARDING_NEXT",
            "ONBOARDING_OPEN_SETTINGS",
            "ONBOARDING_DONE",
            "ONBOARDING_STEP_COUNTER %1$d %2$d",
            "ONBOARDING_SCREENSHOT_PENDING",
            // Reused by the onboarding support link and its no-mail alert.
            "NEED_HELP",
            "ASK_ANYTHING",
            "NO_EMAIL_CONFIGURED",
            "OK"
        ]
        for step in 1...OnboardingPage.stepCount {
            keys.append("ONBOARDING_STEP_\(step)_TITLE")
            keys.append("ONBOARDING_STEP_\(step)_BODY")
        }
        return keys
    }

    /// Keys the tutorial rewrite removed. They must not come back.
    private let retiredKeys = [
        "WELCOME_TITLE", "WELCOME_SUBTITLE", "LETS", "HERE_IS_HOW",
        "ENABLE_SMS_FILTERING", "ON_YOUR_IPHONE", "OPEN_SPACE", "THE_APP",
        "SETTINGS_APP", "TAP", "APPS", "MESSAGES_APP", "TEXT_MESSAGE_FILTER",
        "TOGGLE", "BUTTON_TUTORIAL_FIRST_LAUNCH_TEXT",
        "BUTTON_TUTORIAL_HELP_TEXT", "SETUP_INFO", "1.", "2.", "3.", "4."
    ]

    func testEveryRequiredKeyExistsInEveryLanguage() throws {
        for language in languages {
            let table = try table(for: language)
            for key in requiredKeys {
                let value = table[key]
                XCTAssertNotNil(value, "\(language): missing key \(key)")
                XCTAssertFalse(
                    (value ?? "").trimmingCharacters(in: .whitespaces).isEmpty,
                    "\(language): empty value for \(key)"
                )
            }
        }
    }

    func testRetiredTutorialKeysAreGone() throws {
        for language in languages {
            let table = try table(for: language)
            for key in retiredKeys {
                XCTAssertNil(table[key], "\(language): retired key \(key) is still present")
            }
        }
    }

    func testStepCounterKeepsBothPositionalSpecifiers() throws {
        for language in languages {
            let value = try XCTUnwrap(table(for: language)["ONBOARDING_STEP_COUNTER %1$d %2$d"])
            XCTAssertTrue(value.contains("%1$d"), "\(language): lost the step specifier")
            XCTAssertTrue(value.contains("%2$d"), "\(language): lost the total specifier")
        }
    }

    func testStepCounterFormatsWithoutLeakingSpecifiers() throws {
        for language in languages {
            let format = try XCTUnwrap(table(for: language)["ONBOARDING_STEP_COUNTER %1$d %2$d"])
            let rendered = String.localizedStringWithFormat(format, 3, OnboardingPage.stepCount)
            XCTAssertTrue(rendered.contains("3"), "\(language): step number missing from \(rendered)")
            XCTAssertTrue(rendered.contains("5"), "\(language): step total missing from \(rendered)")
            XCTAssertFalse(rendered.contains("%"), "\(language): unresolved specifier in \(rendered)")
        }
    }

    func testEveryPageResolvesTitleAndBodyCopyInEveryLanguage() throws {
        for language in languages {
            let table = try table(for: language)
            for page in OnboardingPage.allCases {
                let step = page.stepNumber.map(String.init) ?? "WELCOME"
                let titleKey = page == .welcome
                    ? "ONBOARDING_WELCOME_TITLE"
                    : "ONBOARDING_STEP_\(step)_TITLE"
                let bodyKey = page == .welcome
                    ? "ONBOARDING_WELCOME_BODY"
                    : "ONBOARDING_STEP_\(step)_BODY"
                XCTAssertNotNil(table[titleKey], "\(language): \(page) has no title copy")
                XCTAssertNotNil(table[bodyKey], "\(language): \(page) has no body copy")
            }
        }
    }

    func testLanguagesCoverTheSameOnboardingKeys() throws {
        let tables = try languages.map { try table(for: $0) }
        let keySets = tables.map { Set($0.keys.filter { $0.hasPrefix("ONBOARDING_") }) }
        for (index, keys) in keySets.enumerated() {
            XCTAssertEqual(
                keys, keySets[0],
                "\(languages[index]) diverges from \(languages[0]) on onboarding keys"
            )
        }
    }
}
