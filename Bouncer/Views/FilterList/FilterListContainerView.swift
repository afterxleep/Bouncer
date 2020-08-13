//
//  FilterListContainerView.swift
//  Bouncer
//

import SwiftUI

struct FilterListContainerView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        FilterListView(filters: store.state.filters.filters,
                       requiresPurchase: { return requiresPurchase() },
                       onDelete: nil,
                       openSettings: {})
            .environmentObject(store)
    }
}

struct FilterListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListContainerView()
    }
}

extension FilterListContainerView {

    func requiresPurchase() -> Bool {
        if(store.state.filters.filters.count > 8) {
            return true
        }
        return false
    }

}
