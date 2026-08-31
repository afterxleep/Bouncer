//
//  SystemSettings.swift
//  Bouncer
//

import UIKit

/// Thin seam over `UIApplication.shared.open` so a test can assert which URL
/// `SystemSettings.open` asks the system to open. The production implementation
/// is the only one used at runtime; tests substitute a recording spy.
protocol SystemSettingsOpening {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any])
}

private struct UIKitSystemSettingsOpening: SystemSettingsOpening {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any]) {
        UIApplication.shared.open(url, options: options, completionHandler: nil)
    }
}

enum SystemSettings {

    /// Injected so tests can swap in a recording opener. Default is the real
    /// `UIApplication.shared.open` call.
    static var opener: SystemSettingsOpening = UIKitSystemSettingsOpening()

    /// Opens the Settings app at the Bouncer pane.
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        opener.open(url, options: [:])
    }
}

extension Bundle {

    /// "2.1.0 (1324)" — what support needs quoted back to them.
    var displayVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?[kCFBundleVersionKey as String] as? String ?? "?"
        return "\(short) (\(build))"
    }
}