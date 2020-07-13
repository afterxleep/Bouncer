//
//  InstructionsView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct InstructionsView: View {
        
    @AppStorage(APP_STORAGE_KEYS.HAS_LAUNCHED_APP.rawValue) var hasLaunchedApp = false
    @StateObject var viewModel: TutorialViewModel
    @Environment(\.presentationMode) var presentationMode
    
    let separatorColor = Color(red: 0.294, green: 0.357, blue: 0.455)
    let boxBackground = Color(red: 0.004, green: 0.004, blue: 0.004).opacity(0.1)
    
    func respondToActionButton() {
        if(!hasLaunchedApp) {
            viewModel.openSettings()
            hasLaunchedApp = true
        }
        else {
            self.presentationMode.wrappedValue.dismiss()
        }                    
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Group() {
                Text((!hasLaunchedApp) ? "LETS" : "HERE_IS_HOW")
                    .foregroundColor(Color("TextDefaultColor")) +
                Text("ENABLE_SMS_FILTERING")
                    .foregroundColor(Color("TextDefaultColor"))
                    .fontWeight(.bold) +
                Text("ON_YOUR_IPHONE").foregroundColor(Color("TextDefaultColor"))
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
                    Text("OPEN_SPACE")
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold() +
                        Text("THE_APP").foregroundColor(Color("TextDefaultColor"))
                    Image("settings-icon")
                    Text("SETTINGS_APP").foregroundColor(Color("TextDefaultColor"))
                }
                
                HStack {
                    Text("2.").foregroundColor(Color("TextDefaultColor"))
                    Text("TAP")
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold()
                    Image("messages-icon")
                    Text("MESSAGES_APP").foregroundColor(Color("TextDefaultColor"))
                }
                
                HStack {
                    Text("3.").foregroundColor(Color("TextDefaultColor"))
                    Text("TAP")
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold() +
                        Text("UNKNOWN_SOURCES").foregroundColor(Color("TextDefaultColor"))
                }.frame(width: nil, height: 28, alignment: .bottom)
                
                HStack {
                    Text("4.").foregroundColor(Color("TextDefaultColor"))
                    Text("TOGGLE")
                        .foregroundColor(Color("TextHighLightColor"))
                        .bold()
                    Image("toggle-icon")
                    Text( "'Bouncer'").foregroundColor(Color("TextDefaultColor"))
                }
            }
            .padding(.bottom, 35)
            
            Button(action: {
                respondToActionButton()
            }) {
                Text((!hasLaunchedApp) ? "BUTTON_TUTORIAL_FIRST_LAUNCH_TEXT" : "BUTTON_TUTORIAL_HELP_TEXT")
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
            //InstructionsView()
        }
        
    }
}



    

