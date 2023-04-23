//
//  TutorialContainerView.swift
//  Bouncer
//

import SwiftUI
import MessageUI

struct TutorialContainerView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TutorialView(hasLaunchedApp: store.state.settings.hasLaunchedApp,
                     onSettingsTap: openSettings,
                     onContactTap: triggerContact,
                     canSendMail: MFMailComposeViewController.canSendMail())
    }
}

struct TutorialContainerView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView(hasLaunchedApp: false,
                     onSettingsTap: {}, onContactTap: {}, canSendMail: false)
    }
}

extension TutorialContainerView {

    func setAppHasLaunched() {
        store.dispatch(AppAction.settings(action: .setHasLaunchedApp(status: true)))
    }

    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:])
        }
        setAppHasLaunched()
    }

    func triggerContact() {

    }
}
