//
//  UnlockAppView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/20/20.
//

import SwiftUI

struct UnlockAppView: View {
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(alignment: .trailing) {
                Button(action: {}) {
                    Image(systemName: SYSTEM_IMAGES.CLOSE.image)
                        .foregroundColor(SYSTEM_IMAGES.CLOSE.color)
                        .font(.title2)
                        .padding(.top, 20)
                }
                Spacer()
                VStack {
                    Image("welcome_icon").padding()
                    Text("PAYMENT_PAGE_TITLE")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextHighLightColor"))
                        .padding(.bottom, 10.0)
                    Text("PAYMENT_PAGE_MESSAGE")
                        .font(.headline)
                        .foregroundColor(Color("TextDefaultColor"))
                        .padding(.horizontal, 20.0)
                    }
                    Rectangle()
                        .frame(width: 300, height: 1)
                        .foregroundColor(Color("separatorLineColor"))
                        .padding(.top, 10)
                        .padding(.bottom,  15)
                    VStack {
                        Text("UPGRADE_EXPLANATION")
                        .foregroundColor(Color("TextHighLightColor"))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30 )
                        .multilineTextAlignment(.leading)
                        Button(action: {}) {
                            Text("UPGRADE_BUTTON_TEXT")
                                .foregroundColor(Color("TextDefaultColor"))
                                .frame(minWidth: 300, maxWidth: 300, minHeight: 0, maxHeight: 50)
                                .background(Color("ButtonBackgroundColor"))
                                .cornerRadius(DESIGN.BUTTON.CORNER_RADIUS)
                                .padding(.bottom, 10)
                        }
                        Button(action: {}) {
                            Text("RESTORE_PURCHASE")
                                .font(.caption)
                                .foregroundColor(Color("TextDefaultColor"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                    .background(Color("messageBoxBackgroundColor"))
                    .cornerRadius(40)
                Spacer()
            }
            .padding(.horizontal)
            }
        }
    }

struct UnlockAppView_Previews: PreviewProvider {
    static var previews: some View {
        UnlockAppView()
    }
}
