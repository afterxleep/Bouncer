//
//  AddButtonView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 8/12/20.
//

import SwiftUI

struct AddButton: View {
    var requiresPurchase: (() -> Bool)

    @State var showingAddForm = false
    @State var showingInApp = false

    var body: some View {
        Group {
            if (requiresPurchase()) {
                Button(
                    action: { self.showingInApp = true }) {
                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                    }.sheet(isPresented: self.$showingInApp) {
                        UnlockAppView()
                    }
            } else {
                Button(
                    action: { self.showingAddForm = true }) {
                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                    }.sheet(isPresented: self.$showingAddForm) {

                    }
            }
        }
    }
}
