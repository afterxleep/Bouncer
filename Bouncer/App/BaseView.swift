//
//  BaseView.swift
//  Bouncer
//

import SwiftUI

struct BaseView: View {
    @EnvironmentObject var store: AppStore
    
    init() {
        customizeNavbar()
    }
    
    var body: some View {
        Group {            
            if(!store.state.settings.hasLaunchedApp) {
                TutorialContainerView().environmentObject(store)
            }
            else {
                FilterListContainerView().environmentObject(store)
            }
        }
    }

}

extension BaseView {

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
            .foregroundColor: UIColor(named: "TextHighLightColor") ?? .white
        ]
        appearance.largeTitleTextAttributes = attrs
        appearance.titleTextAttributes = attrs
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance

        // Set SearchBar background color to default white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.init(named: "DefaultColor")

    }
}

struct BaseView_Previews: PreviewProvider {
    static var previews: some View {
        BaseView()
    }
}
