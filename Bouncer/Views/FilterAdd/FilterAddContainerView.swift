//
//  FilterAddContainerView.swift
//  Bouncer
//

import SwiftUI

struct FilterAddContainerView: View {
    @EnvironmentObject var store: AppStore
    

    var body: some View {
        FilterAddView(onAdd: saveFilter)
    }
}

struct FilterAddContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterAddContainerView()
    }
}

extension FilterAddContainerView {

    fileprivate func saveFilter(filter: Filter) {
        store.dispatch(.filter(action: .add(filter: filter)))
    }
}
