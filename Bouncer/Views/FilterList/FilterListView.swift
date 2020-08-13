//
//  FilterListView.swift
//  Bouncer
//

import SwiftUI

struct FilterListView: View {
    var filters: [Filter]
    var requiresPurchase: (() -> Bool)
    let onDelete: ((IndexSet) -> Void)?
    let openSettings: () -> Void

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
                .navigationBarItems(leading: HelpButton(openSettings: openSettings), trailing: AddButton(requiresPurchase: requiresPurchase))
            }
        }
    }
}



struct FilterListView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListView(filters: [],
                       requiresPurchase: { return false },
                       onDelete: nil,
                       openSettings: {}
        )
    }
}
