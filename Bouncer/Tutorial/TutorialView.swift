//
//  TutorialView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/19/20.
//

import SwiftUI

struct TutorialView: View {
        
    @EnvironmentObject var appSettings: UserSettingsDefaults
    var firstLaunch: Bool = true
    
    enum LocalizedStrings: LocalizedStringKey {
        case helloThere = "Hello There!"
        case welcomeToBouncer = "Welcome to Bouncer!"
        case help = "Help"
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                VStack {
                    Image("welcome_icon").padding()
                    if(firstLaunch) {
                        Text(LocalizedStrings.helloThere.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DESIGN.TEXT.DARK.HG_COLOR)
                        Text(LocalizedStrings.welcomeToBouncer.rawValue)
                            .font(.largeTitle)
                            .foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                            .padding(.bottom, 60.0)
                    }
                    else {
                        Text(LocalizedStrings.help.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DESIGN.TEXT.DARK.HG_COLOR)
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


