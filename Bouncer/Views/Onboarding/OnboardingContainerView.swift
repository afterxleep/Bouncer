//
//  OnboardingContainerView.swift
//  Bouncer
//

import SwiftUI
import MessageUI

struct OnboardingContainerView: View {
    enum Mode { case firstRun, help }

    var mode: Mode = .firstRun

    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OnboardingView(mode: mode == .help ? .help : .firstRun,
                       canSendMail: MFMailComposeViewController.canSendMail(),
                       onOpenSettings: SystemSettings.open,
                       onFinish: finish)
    }
}

extension OnboardingContainerView {

    func finish() {
        switch mode {
        case .firstRun:
            store.dispatch(AppAction.settings(action: .setHasLaunchedApp(status: true)))
        case .help:
            dismiss()
        }
    }
}

struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(mode: .firstRun,
                       canSendMail: false,
                       onOpenSettings: {},
                       onFinish: {})
    }
}
