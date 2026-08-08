//
//  SystemSettings.swift
//  Bouncer
//

import UIKit

enum SystemSettings {

    /// Opens the Settings app at its root rather than Bouncer's own page, so the
    /// user lands where the setup steps expect them.
    ///
    /// `UIApplication.openSettingsURLString` always deep-links to the app's own
    /// settings pane; there is no public API for the Settings root, so this uses
    /// the `App-Prefs:` scheme and falls back to the public one if the system
    /// refuses to open it.
    static func open() {
        guard let root = URL(string: "App-Prefs:") else {
            openAppPane()
            return
        }
        UIApplication.shared.open(root, options: [:]) { opened in
            if !opened { openAppPane() }
        }
    }

    private static func openAppPane() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
