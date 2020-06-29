//
//  BaseView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct BaseView: View {
    
    @EnvironmentObject var appSettings: UserSettingsDefaults
    
    init() {
        customizeNavbar()
    }
    
    var body: some View {
        Group {
            if(!appSettings.hasLaunchedApp) {
                TutorialView()
            } else {
                FilterListView()
                    .background(DESIGN.UI.DARK.MAIN_BG_COLOR)
            }
        }
    }
    
    func customizeNavbar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = DESIGN.NAVIGATIONBAR.DARK.BACKGROUND_COLOR
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: DESIGN.NAVIGATIONBAR.DARK.TITLE_COLOR
        ]
        appearance.largeTitleTextAttributes = attrs
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct BaseView_Previews: PreviewProvider {
    static var previews: some View {
        BaseView()
    }
}
