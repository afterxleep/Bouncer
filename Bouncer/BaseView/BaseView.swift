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
                    .background(Color("MainBackgroundColor"))
            }
        }
    }
    
    func customizeNavbar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(named: "NavigationBarBackgroundColor")
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(named: "TextDefaultColor") ?? .white
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
