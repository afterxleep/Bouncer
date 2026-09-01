//
//  ErrorAlertLocalizationTests.swift
//  BouncerTests
//
//  Guards the localised strings used by FilterError's alert path: every key
//  the UI asks for exists in every shipped language, and the corrupt-store
//  alert copy now tells the user their rules were reset, not to reinstall.
//

import XCTest
@testable import Bouncer

final class ErrorAlertLocalizationTests: XCTestCase {

    private let languages = ["en", "es"]

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

    func testLoadFailedAlertWarnsOfResetInEveryLanguage() throws {
        // Substrings per language the alert must contain, proving it tells
        // the user their rules were reset rather than asking them to
        // reinstall.
        let mustContain: [String: [String]] = [
            "en": ["reset"],
            "es": ["restablec"],   // restablecido / restablecer
        ]
        for language in languages {
            let value = try XCTUnwrap(
                table(for: language)["ERROR_LOAD_FAILED"],
                "\(language): missing ERROR_LOAD_FAILED"
            )
            let lower = value.lowercased()
            let needles = mustContain[language] ?? []
            for needle in needles {
                XCTAssertTrue(
                    lower.contains(needle),
                    "\(language): ERROR_LOAD_FAILED does not contain \"\(needle)\": \(value)"
                )
            }
            XCTAssertFalse(
                lower.contains("reinstall") || lower.contains("reinstala"),
                "\(language): ERROR_LOAD_FAILED still tells the user to reinstall; the reset is silent: \(value)"
            )
        }
    }

    func testErrorAlertKeySetsMatchAcrossLanguages() throws {
        let tables = try languages.map { try table(for: $0) }
        let keySets = tables.map { Set($0.keys.filter { $0.hasPrefix("ERROR_") }) }
        for (index, keys) in keySets.enumerated() {
            XCTAssertEqual(
                keys, keySets[0],
                "\(languages[index]) diverges from \(languages[0]) on ERROR_ keys"
            )
        }
    }
}