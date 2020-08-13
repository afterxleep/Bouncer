//
//  FilterListContainerView.swift
//  Bouncer
//

import SwiftUI

struct FilterListContainerView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        FilterListView(filters: store.state.filters.filters,
                       purchasedApp: false,
                       onDelete: nil)
            .environmentObject(store)
    }
}

struct FilterListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListContainerView()
    }
}
