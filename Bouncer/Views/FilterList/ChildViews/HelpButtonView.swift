//
//  HelpButtonView.swift
//  Bouncer
//

import SwiftUI

struct HelpButton: View {
    let openSettings: () -> Void
    @State var showingSettings = false

    var body: some View {
        Group {
            Button(action: { self.showingSettings = true }) {
                Image(systemName: SYSTEM_IMAGES.HELP.image).imageScale(.large)
            }.sheet(isPresented: self.$showingSettings) {
                TutorialView(hasLaunchedApp: true, onSettingsTap: openSettings)
            }
        }
    }
}
