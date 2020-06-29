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
    
    var body: some Scene {
        WindowGroup {
            BaseView()
                .environmentObject(appSettings)
        }
    }
}
