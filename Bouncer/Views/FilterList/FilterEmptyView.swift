//
//  FilterEmptyView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 8/13/20.
//

import SwiftUI

struct FilterEmptyView: View {
    var body: some View {
        VStack(alignment: .center) {
            Group() {
                Text("EMPTY_LIST_TITLE").font(.title2).bold().padding()
                Group {
                    Text("EMPTY_LIST_MESSAGE")
                    HStack(spacing: 0) {
                        Text("TAP_SPACE")
                        Image(systemName: "plus.circle")
                        Text("TO_ADD_A_FILTER_SPACE")
                    }
                }.frame(width: 260)
            }
            .foregroundColor(Color("TextHighLightColor"))
            .multilineTextAlignment(.center)
        }.padding(.bottom, 200)
    }
}

struct FilterEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        FilterEmptyView()
    }
}
