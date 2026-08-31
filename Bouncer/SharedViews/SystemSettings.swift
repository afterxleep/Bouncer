//
//  SystemSettings.swift
//  Bouncer
//

import UIKit

enum SystemSettings {

    /// Opens the Settings app at the Bouncer pane. The setup steps walk the user
    /// from there to Apps → Messages → Text Message Filtering, so the Bouncer
    /// pane is the right landing place.
    static func open() {
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
