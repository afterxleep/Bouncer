//
//  InstructionsView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct InstructionsView: View {
    var viewModel: TutorialViewModel
    
    enum LocalizedStrings: LocalizedStringKey {
        case lets = "Let's "
        case enableSMS = "enable SMS Filtering"
        case onYouriPhone = " on your iPhone!"
        case open = "Open "
        case the = "the"
        case settingsApp = "'Settings App'"
        case tap = "Tap "
        case messages = "'Messages'"
        case unknownAndSpam = "'Unknown and Spam'"
        case toggle = "Toggle"
        case bouncer = "'Bouncer'"
        case takeMeToSettings = "Take me to Settings!"
    }    
    
    let separatorColor = Color(red: 0.294, green: 0.357, blue: 0.455)
    let boxBackground = Color(red: 0.004, green: 0.004, blue: 0.004).opacity(0.1)
    
    func navigateToSettings() {        
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:])}
            viewModel.firstLaunchCompleted()
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Group() {
                Text(LocalizedStrings.lets.rawValue).foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR) +
                    Text(LocalizedStrings.enableSMS.rawValue)
                    .foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                    .fontWeight(.bold) +
                    Text(LocalizedStrings.onYouriPhone.rawValue).foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
            }
            .padding(.horizontal, 40.0)
            .padding(.top, 40)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            
            Rectangle()
                .frame(width: 300, height: 1)
                .foregroundColor(separatorColor)
                .padding(.top, 10)
                .padding(.bottom,  15)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("1.").foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                    Text(LocalizedStrings.open.rawValue)
                        .foregroundColor(DESIGN.TEXT.DARK.HG_COLOR)
                        .bold() +
                        Text(LocalizedStrings.the.rawValue).foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                    Image("settings-icon")
                    Text(LocalizedStrings.settingsApp.rawValue).foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                }
                
                HStack {
                    Text("2.").foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                    Text(LocalizedStrings.tap.rawValue)
                        .foregroundColor(DESIGN.TEXT.DARK.HG_COLOR)
                        .bold()
                    Image("messages-icon")
                    Text(LocalizedStrings.messages.rawValue).foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                }
                
                HStack {
                    Text("3.").foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                    Text(LocalizedStrings.tap.rawValue)
                        .foregroundColor(DESIGN.TEXT.DARK.HG_COLOR)
                        .bold() +
                        Text(LocalizedStrings.unknownAndSpam.rawValue).foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                }.frame(width: nil, height: 30, alignment: .bottom)
                
                HStack {
                    Text("4.").foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                    Text(LocalizedStrings.toggle.rawValue)
                        .foregroundColor(DESIGN.TEXT.DARK.HG_COLOR)
                        .bold()
                    Image("toggle-icon")
                    Text(LocalizedStrings.bouncer.rawValue).foregroundColor(DESIGN.TEXT.DARK.DEFAULT_COLOR)
                }
            }
            .padding(.bottom, 35)
            
            Button(action: {
                navigateToSettings()
            }) {
                Text(LocalizedStrings.takeMeToSettings.rawValue)
                    .foregroundColor(DESIGN.BUTTON.DARK.TEXT_COLOR)
                    .frame(minWidth: 300, maxWidth: 300, minHeight: 0, maxHeight: 50)
                    .background(DESIGN.BUTTON.DARK.BG_COLOR)
                    .cornerRadius(DESIGN.BUTTON.CORNER_RADIUS)
                    .padding(.bottom, 40)
            }
        }
        .padding(.horizontal)
        .background(boxBackground)
        .cornerRadius(40)
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            BackgroundView()
            InstructionsView(viewModel: TutorialViewModel())
        }
        
    }
}



    

