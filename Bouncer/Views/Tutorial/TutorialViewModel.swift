//
//  TutorialViewModel.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/12/20.
//

import Foundation
import SwiftUI

class TutorialViewModel: ObservableObject {
    
    var appSettings: AppSettingsStore
    
    init(appSettings: AppSettingsStore) {
        self.appSettings = appSettings
    }
    
    func saveHasLaunchedApp() {
        //userSettingsService.numberOfLaunches = userSettingsService.numberOfLaunches + 1
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:])}
    }
    
    func setAppHasLaunched() {
        
    }
        
}
