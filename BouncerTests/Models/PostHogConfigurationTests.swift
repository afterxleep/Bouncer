//
//  PostHogConfigurationTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer

final class PostHogConfigurationTests: XCTestCase {

    private let bundle: [String: Any] = [
        "PostHogProjectToken": "phc_bundle",
        "PostHogHost": "eu.i.posthog.com",
    ]

    func testEnvironmentWinsOverTheBundle() {
        let credentials = PostHogConfiguration.resolve(
            environment: ["POSTHOG_PROJECT_TOKEN": "phc_env", "POSTHOG_HOST": "https://env.example.com"],
            bundleInfo: bundle)
        XCTAssertEqual(credentials, .init(projectToken: "phc_env", host: "https://env.example.com"))
    }

    func testShippedBuildsFallBackToTheBundle() {
        let credentials = PostHogConfiguration.resolve(environment: [:], bundleInfo: bundle)
        XCTAssertEqual(credentials, .init(projectToken: "phc_bundle", host: "https://eu.i.posthog.com"))
    }

    func testEmptyEnvironmentValuesFallBackToTheBundle() {
        let credentials = PostHogConfiguration.resolve(
            environment: ["POSTHOG_PROJECT_TOKEN": "", "POSTHOG_HOST": ""], bundleInfo: bundle)
        XCTAssertEqual(credentials?.projectToken, "phc_bundle")
    }

    func testABareHostGetsHTTPS() {
        let credentials = PostHogConfiguration.resolve(
            environment: [:], bundleInfo: ["PostHogProjectToken": "t", "PostHogHost": " us.i.posthog.com "])
        XCTAssertEqual(credentials?.host, "https://us.i.posthog.com")
    }

    func testAFullURLIsKeptAsIs() {
        let credentials = PostHogConfiguration.resolve(
            environment: [:], bundleInfo: ["PostHogProjectToken": "t", "PostHogHost": "http://localhost:8000"])
        XCTAssertEqual(credentials?.host, "http://localhost:8000")
    }

    func testAnUnexpandedBuildSettingCountsAsMissing() {
        let credentials = PostHogConfiguration.resolve(
            environment: [:],
            bundleInfo: ["PostHogProjectToken": "$(POSTHOG_PROJECT_TOKEN)", "PostHogHost": "$(POSTHOG_HOST)"])
        XCTAssertNil(credentials)
    }

    func testEitherValueMissingMeansNoAnalytics() {
        XCTAssertNil(PostHogConfiguration.resolve(environment: [:], bundleInfo: ["PostHogHost": "h"]))
        XCTAssertNil(PostHogConfiguration.resolve(environment: [:], bundleInfo: ["PostHogProjectToken": "t"]))
        XCTAssertNil(PostHogConfiguration.resolve(environment: [:], bundleInfo: [:]))
    }
}
