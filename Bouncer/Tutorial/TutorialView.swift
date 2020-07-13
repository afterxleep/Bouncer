//
//  TutorialView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/19/20.
//

import SwiftUI

struct TutorialView: View {
    
    @AppStorage(APP_STORAGE_KEYS.HAS_LAUNCHED_APP.rawValue) var hasLaunchedApp = false
    @StateObject var viewModel: TutorialViewModel = TutorialViewModel()
    
    var firstLaunch: Bool = true
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                VStack {
                    Image("welcome_icon").padding()
                    if(!hasLaunchedApp) {
                        Text("WELCOME_TITLE")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("TextHighLightColor"))
                        Text("WELCOME_SUBTITLE")
                            .font(.largeTitle)
                            .foregroundColor(Color("TextDefaultColor"))
                            .padding(.bottom, 60.0)
                    }
                    else {
                        Text("HELP")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("TextHighLightColor"))
                            .padding(.bottom, 20.0)
                    }
                }
                InstructionsView(viewModel: viewModel)
            }
        }
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}


