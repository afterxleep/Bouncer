//
//  InstructionsView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct InstructionsView: View {
    
    @EnvironmentObject var appSettings: UserSettingsDefaults
    @Environment(\.presentationMode) var presentationMode
    var firstLaunch: Bool = true
    
    enum LocalizedStrings: LocalizedStringKey {
        case lets = "Let's "
        case howTo = "Here's how to "
        case enableSMS = "enable SMS Filtering"
        case onYouriPhone = " on your iPhone"
        case open = "Open "
        case the = "the"
        case settingsApp = "'Settings App'"
        case tap = "Tap "
        case messages = "'Messages'"
        case unknownAndSpam = "'Unknown and Spam'"
        case toggle = "Toggle"
        case bouncer = "'Bouncer'"
        case takeMeToSettings = "Take me to Settings!"
        case gotIt = "Got it!"
    }    
    
    let separatorColor = Color(red: 0.294, green: 0.357, blue: 0.455)
    let boxBackground = Color(red: 0.004, green: 0.004, blue: 0.004).opacity(0.1)
    
    func respondToActionButton() {
        if(firstLaunch) {
            appSettings.hasLaunchedApp = true
            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:])}
        }
        else {
            self.presentationMode.wrappedValue.dismiss()
        }
                    
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Group() {
                Text((firstLaunch) ? LocalizedStrings.lets.rawValue : LocalizedStrings.howTo.rawValue)
                    .foregroundColor(Color("TextDefaultColor")) +
                Text(LocalizedStrings.enableSMS.rawValue)
                    .foregroundColor(Color("TextDefaultColor"))
                    .fontWeight(.bold) +
                Text(LocalizedStrings.onYouriPhone.rawValue).foregroundColor(Color("TextDefaultColor"))
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
                    Text("1.").foregroundColor(Color("TextDefaultColor"))
                    Text(LocalizedStrings.open.rawValue)
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold() +
                        Text(LocalizedStrings.the.rawValue).foregroundColor(Color("TextDefaultColor"))
                    Image("settings-icon")
                    Text(LocalizedStrings.settingsApp.rawValue).foregroundColor(Color("TextDefaultColor"))
                }
                
                HStack {
                    Text("2.").foregroundColor(Color("TextDefaultColor"))
                    Text(LocalizedStrings.tap.rawValue)
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold()
                    Image("messages-icon")
                    Text(LocalizedStrings.messages.rawValue).foregroundColor(Color("TextDefaultColor"))
                }
                
                HStack {
                    Text("3.").foregroundColor(Color("TextDefaultColor"))
                    Text(LocalizedStrings.tap.rawValue)
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold() +
                        Text(LocalizedStrings.unknownAndSpam.rawValue).foregroundColor(Color("TextDefaultColor"))
                }.frame(width: nil, height: 28, alignment: .bottom)
                
                HStack {
                    Text("4.").foregroundColor(Color("TextDefaultColor"))
                    Text(LocalizedStrings.toggle.rawValue)
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold()
                    Image("toggle-icon")
                    Text(LocalizedStrings.bouncer.rawValue).foregroundColor(Color("TextDefaultColor"))
                }
            }
            .padding(.bottom, 35)
            
            Button(action: {
                respondToActionButton()
            }) {
                Text((firstLaunch) ? LocalizedStrings.takeMeToSettings.rawValue : LocalizedStrings.gotIt.rawValue)
                    .foregroundColor(Color("TextDefaultColor"))
                    .frame(minWidth: 300, maxWidth: 300, minHeight: 0, maxHeight: 50)
                    .background(Color("ButtonBackgroundColor"))
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
            InstructionsView()
        }
        
    }
}



    

