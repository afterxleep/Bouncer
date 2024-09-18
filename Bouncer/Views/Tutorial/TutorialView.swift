//
//  TutorialView.swift
//  Bouncer
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingContactView = false
    @State private var isShowingAlert = false

    var hasLaunchedApp: Bool
    let onSettingsTap: (() -> Void)?
    let onContactTap: (() -> Void)?
    let canSendMail: Bool

    private var header: some View {
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
                    .padding(.bottom, 20.0)
            }
            else {
                Text("HELP")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextHighLightColor"))
            }
        }
    }

    private var instructions: some View {
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
                Image("apps-icon")
                Text("APPS").foregroundColor(Color("TextDefaultColor"))
            }
            
            HStack {
                Text("3.").foregroundColor(Color("TextDefaultColor"))
                Text("TAP")
                    .foregroundColor(Color("TextHighLightColor"))
                    .bold()
                Image("messages-icon")
                Text("MESSAGES_APP").foregroundColor(Color("TextDefaultColor"))
            }

            HStack {
                Text("4.").foregroundColor(Color("TextDefaultColor"))
                Text("TAP")
                    .foregroundColor(Color("TextHighLightColor"))
                    .bold() +
                    Text("UNKNOWN_SOURCES").foregroundColor(Color("TextDefaultColor"))
            }

            HStack {
                Text("5.").foregroundColor(Color("TextDefaultColor"))
                Text("TOGGLE")
                    .foregroundColor(Color("TextHighLightColor"))
                    .bold()
                Image("toggle-icon")
                Text( "'Bouncer'").foregroundColor(Color("TextDefaultColor"))
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            if(!hasLaunchedApp) {
                (onSettingsTap ?? {})()
            } else {
                presentationMode.wrappedValue.dismiss()
            }

        }) {
            Text((!hasLaunchedApp) ? "BUTTON_TUTORIAL_FIRST_LAUNCH_TEXT" : "BUTTON_TUTORIAL_HELP_TEXT")
                .foregroundColor(Color("TextHighLightColor"))
                .frame(minWidth: 280, maxWidth: 280, minHeight: 0, maxHeight: 50)
                .background(Color("ButtonBackgroundColor"))
                .cornerRadius(DESIGN.BUTTON.CORNER_RADIUS)
                .padding(.bottom, 40)
                .font(Font.headline)
        }
    }

    private var supportButton: some View {
        VStack(alignment: .center) {
            Button(action:  {
                if canSendMail {
                    isShowingContactView.toggle()
                } else {
                    isShowingAlert.toggle()
                }
            }) {
                Text("NEED_HELP")
                    .foregroundColor(Color("TextHighLightColor"))
                    .cornerRadius(DESIGN.BUTTON.CORNER_RADIUS)
                    .font(Font.headline)
                    .underline()
            }
            .sheet(isPresented: $isShowingContactView) {
                ContactView(result: self.$isShowingContactView)
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text("ASK_ANYTHING"),
                    message: Text("NO_EMAIL_CONFIGURED"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var instructionsBackground: some View {
        Rectangle()
            .frame(width: 280, height: 1)
            .foregroundColor(Color("separatorLineColor"))
            .padding(.top, 10)
            .padding(.bottom,  15)

    }

    private var title: some View {
        Group() {
            Text((!hasLaunchedApp) ? "LETS" : "HERE_IS_HOW")
                .foregroundColor(Color("TextDefaultColor")) +
            Text("ENABLE_SMS_FILTERING")
                .foregroundColor(Color("TextDefaultColor"))
                .fontWeight(.bold) +
            Text("ON_YOUR_IPHONE").foregroundColor(Color("TextDefaultColor"))
        }
    }

    var body: some View {
        ZStack {
            BackgroundView()            
            VStack {
                header
                VStack(alignment: .center) {
                    title
                    .padding(.horizontal, 20.0)
                    .padding(.top, 20)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    instructionsBackground
                    instructions.padding(.bottom, 20)
                    actionButton
                }
                .padding(.horizontal, 10)
                .frame(minWidth: 320, maxWidth: 340)
                .background(Color("messageBoxBackgroundColor"))
                .cornerRadius(40)
                supportButton
            }

        }
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView(hasLaunchedApp: false,
                     onSettingsTap: {},
                     onContactTap: {},
                     canSendMail: false)
    }
}


