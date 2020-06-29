//
//  BouncerApp.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/24/20.
//

import SwiftUI

@main
struct BouncerApp: App {
    
    var appSettings: UserSettingsDefaults = UserSettingsDefaults()
    
    @available(iOS 14.0, *)
    var body: some Scene {
        WindowGroup {
            BaseView()
                .environmentObject(appSettings)
        }
    }
}
