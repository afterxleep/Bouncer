//
//  BaseView.swift
//  Bouncer
//

import SwiftUI

struct BaseView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if store.state.settings.hasLaunchedApp {
                FilterListContainerView().environmentObject(store)
            } else {
                OnboardingContainerView().environmentObject(store)
            }
        }
        .animation(.smooth, value: store.state.settings.hasLaunchedApp)
        .tint(Brand.tint)
    }
}

struct BaseView_Previews: PreviewProvider {
    static var previews: some View {
        BaseView()
    }
}
