//
//  OnboardingPageTests.swift
//  BouncerTests
//

import XCTest
import SwiftUI
@testable import Bouncer

final class OnboardingPageTests: XCTestCase {

    // MARK: - Page set

    func testPageOrderIsWelcomeThenFiveSteps() {
        XCTAssertEqual(OnboardingPage.allCases,
                       [.welcome, .step1, .step2, .step3, .step4, .step5])
    }

    func testStepCountExcludesWelcome() {
        XCTAssertEqual(OnboardingPage.stepCount, 5)
        XCTAssertEqual(OnboardingPage.allCases.count, OnboardingPage.stepCount + 1)
    }

    func testIdentifiableIdMatchesRawValue() {
        for page in OnboardingPage.allCases {
            XCTAssertEqual(page.id, page.rawValue)
        }
    }

    // MARK: - Step numbering

    func testWelcomeHasNoStepNumber() {
        XCTAssertNil(OnboardingPage.welcome.stepNumber)
    }

    func testStepPagesAreNumberedOneThroughFive() {
        XCTAssertEqual(OnboardingPage.step1.stepNumber, 1)
        XCTAssertEqual(OnboardingPage.step2.stepNumber, 2)
        XCTAssertEqual(OnboardingPage.step3.stepNumber, 3)
        XCTAssertEqual(OnboardingPage.step4.stepNumber, 4)
        XCTAssertEqual(OnboardingPage.step5.stepNumber, 5)
    }

    func testEveryStepNumberIsWithinTheStepCount() {
        for page in OnboardingPage.allCases where page != .welcome {
            let number = try? XCTUnwrap(page.stepNumber)
            XCTAssertNotNil(number)
            XCTAssertGreaterThanOrEqual(number!, 1)
            XCTAssertLessThanOrEqual(number!, OnboardingPage.stepCount)
        }
    }

    // MARK: - Screenshot assets

    func testWelcomeHasNoImage() {
        XCTAssertNil(OnboardingPage.welcome.imageName)
    }

    func testStepImageNamesMatchTheAssetCatalogFolders() {
        XCTAssertEqual(OnboardingPage.step1.imageName, "onboarding-step-1")
        XCTAssertEqual(OnboardingPage.step2.imageName, "onboarding-step-2")
        XCTAssertEqual(OnboardingPage.step3.imageName, "onboarding-step-3")
        XCTAssertEqual(OnboardingPage.step4.imageName, "onboarding-step-4")
        XCTAssertEqual(OnboardingPage.step5.imageName, "onboarding-step-5")
    }

    func testImageNamesAreUnique() {
        let names = OnboardingPage.allCases.compactMap { $0.imageName }
        XCTAssertEqual(names.count, OnboardingPage.stepCount)
        XCTAssertEqual(Set(names).count, names.count)
    }

    // MARK: - Accessibility identifiers

    func testAccessibilityIdentifiers() {
        XCTAssertEqual(OnboardingPage.welcome.accessibilityIdentifier, "onboarding.page.welcome")
        XCTAssertEqual(OnboardingPage.step1.accessibilityIdentifier, "onboarding.page.step1")
        XCTAssertEqual(OnboardingPage.step5.accessibilityIdentifier, "onboarding.page.step5")
    }

    func testAccessibilityIdentifiersAreUnique() {
        let ids = OnboardingPage.allCases.map { $0.accessibilityIdentifier }
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    // MARK: - Copy

    func testEveryPageHasADistinctTitleAndBodyKey() {
        let titles = OnboardingPage.allCases.map { $0.titleKey }
        let bodies = OnboardingPage.allCases.map { $0.bodyKey }
        for title in titles {
            XCTAssertEqual(titles.filter { $0 == title }.count, 1)
        }
        for body in bodies {
            XCTAssertEqual(bodies.filter { $0 == body }.count, 1)
        }
    }

    func testTitleAndBodyKeysMatchTheLocalizationTable() {
        XCTAssertEqual(OnboardingPage.welcome.titleKey, LocalizedStringKey("ONBOARDING_WELCOME_TITLE"))
        XCTAssertEqual(OnboardingPage.welcome.bodyKey, LocalizedStringKey("ONBOARDING_WELCOME_BODY"))
        XCTAssertEqual(OnboardingPage.step3.titleKey, LocalizedStringKey("ONBOARDING_STEP_3_TITLE"))
        XCTAssertEqual(OnboardingPage.step3.bodyKey, LocalizedStringKey("ONBOARDING_STEP_3_BODY"))
    }
}
