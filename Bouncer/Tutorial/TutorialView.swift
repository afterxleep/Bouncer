//
//  TutorialView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/19/20.
//

import SwiftUI

struct TutorialView: View {
        
    @EnvironmentObject var userSettings: UserSettings
    var firstLaunch: Bool = true
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                VStack {
                    Image("welcome_icon").padding()
                    if(firstLaunch) {
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
                InstructionsView(firstLaunch: firstLaunch)
            }
        }
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}


