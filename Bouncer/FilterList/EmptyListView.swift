//
//  EmptyListView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/29/20.
//

import SwiftUI

struct EmptyListView: View {
    var body: some View {
        VStack(alignment: .center) {
            Group() {
                Text("Your Block List is Empty").font(.title2).bold().padding()
                Group {
                    Text("Bouncer will block SMS messages from unknown senders using the filters you add here.")
                    HStack(spacing: 0) {
                        Text("Tap '")
                        Image(systemName: "plus.circle")
                        Text("' to add a filter.")
                    }
                }.frame(width: 260)
            }
            .foregroundColor(Color("TextHighLightColor"))
            .multilineTextAlignment(.center)
        }.padding(.bottom, 200)
    }
}

struct EmptyListView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyListView()
    }
}
