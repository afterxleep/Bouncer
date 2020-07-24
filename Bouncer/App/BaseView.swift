//
//  BaseView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct BaseView: View {
        
    @AppStorage(APP_STORAGE_KEYS.HAS_LAUNCHED_APP.rawValue) var hasLaunchedApp = false    
    @EnvironmentObject var store: AppStore
    
    init() {
        customizeNavbar()
    }
    
    var body: some View {
        Group {
            if(!hasLaunchedApp) {
                TutorialView()
            } else {                
                FilterListContainerView()
                    .environmentObject(store)
                    .background(Color("MainBackgroundColor"))
            }
        }
    }
    
    func customizeNavbar() {
        let image = UIImage.gradientImageWithBounds(
            bounds: CGRect(x: 0, y: 0, width: 1, height: 11),
            colors: [
                UIColor(named: "NavigationBarGradient1Color")!.cgColor,
                UIColor(named: "NavigationBarGradient2Color")!.cgColor
            ]
        )
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(named: "NavigationBarBackgroundColor")
        appearance.backgroundImage = image
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
