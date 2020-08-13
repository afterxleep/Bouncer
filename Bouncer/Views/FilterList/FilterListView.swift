//
//  FilterListView.swift
//  Bouncer
//

import SwiftUI

struct FilterListView: View {
    var filters: [Filter]
    var purchasedApp: Bool
    var showingSettings = false
    var showingAddForm = false
    var showingInApp = false
    let onDelete: ((IndexSet) -> Void)?
    
    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                Group {
                    if(filters.count > 0) {
                        List {
                            ForEach(filters) { filter in
                               FilterRowView(filter: filter)
                            }.onDelete(perform: onDelete)
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        EmptyListView()                        
                    }
                }
                .navigationBarTitle("LIST_VIEW_TITLE")
                .navigationBarItems(leading:
                                        Button(action: {  }) {
                                            Image(systemName: SYSTEM_IMAGES.HELP.image).imageScale(.large)
                                        },
                                    trailing:
                                        Group {
                                            if (purchasedApp) {
                                                Button(
                                                    action: { }) {
                                                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                                                    }
                                            } else {
                                                Button(
                                                    action: { }) {
                                                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                                                    }
                                            }
                                        }
                )
            }

        }
    }
}



struct FilterListView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListView(filters: [],
                       purchasedApp: false,
                       onDelete: nil
        )
    }
}
