import Foundation
import os.log
import PostHog

enum PostHogConfiguration {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Bouncer", category: "PostHog")

    struct Credentials: Equatable {
        let projectToken: String
        let host: String
    }

    /// Reads the project token and host. The process environment wins, so a
    /// scheme can point a debug run somewhere else; shipped builds have no
    /// environment, so they fall back to values baked into Info.plist from the
    /// `POSTHOG_*` build settings.
    static func resolve(environment: [String: String], bundleInfo: [String: Any]) -> Credentials? {
        func value(env: String, plist: String) -> String? {
            let candidates = [environment[env], bundleInfo[plist] as? String]
            return candidates
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                // An unexpanded `$(NAME)` means the build setting was never defined.
                .first { !$0.isEmpty && !$0.hasPrefix("$(") }
        }

        guard let token = value(env: "POSTHOG_PROJECT_TOKEN", plist: "PostHogProjectToken"),
              let host = value(env: "POSTHOG_HOST", plist: "PostHogHost") else { return nil }
        // xcconfig treats `//` as a comment, so the host is stored without its scheme.
        let normalizedHost = host.contains("://") ? host : "https://\(host)"
        return Credentials(projectToken: token, host: normalizedHost)
    }

    /// `optedIn` is the user's stored answer: until it is `true` the SDK starts
    /// opted out, so not even its automatic lifecycle or crash events are sent.
    static func configure(optedIn: Bool) {
        guard let credentials = resolve(environment: ProcessInfo.processInfo.environment,
                                        bundleInfo: Bundle.main.infoDictionary ?? [:]) else {
            reportMissingConfiguration()
            return
        }

        let config = PostHogConfig(projectToken: credentials.projectToken, host: credentials.host)
        config.optOut = !optedIn
        config.errorTrackingConfig.autoCapture = true
        config.logs.serviceName = "bouncer-ios"
        PostHogSDK.shared.setup(config)
    }

    /// A missing token must not take the app down: unit tests host the app
    /// without one, and a crash here would also ship to anyone whose build
    /// lacks the setting.
    private static func reportMissingConfiguration() {
        logger.warning("POSTHOG_PROJECT_TOKEN or POSTHOG_HOST is missing; analytics events will not be sent")
    }
}

/// Adapts the app's analytics seam to the PostHog SDK. The SDK is only touched
/// here, so swapping or removing it is a one-file change.
struct PostHogAnalyticsTracker: AnalyticsTracking {

    func track(_ event: AnalyticsEvent) {
        PostHogSDK.shared.capture(event.name, properties: event.properties.sdkRepresentation)
    }

    func register(_ properties: AnalyticsProperties) {
        PostHogSDK.shared.register(properties.sdkRepresentation)
    }

    func setCollectionEnabled(_ enabled: Bool) {
        if enabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
            // New anonymous identity and no leftover properties if they come back.
            PostHogSDK.shared.reset()
        }
    }
}
