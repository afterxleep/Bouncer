//
//  FilterAddContainerView.swift
//  Bouncer
//

import SwiftUI

struct FilterAddContainerView: View {
    @EnvironmentObject var store: AppStore
    var interactionType: InteractionType = .add
    var filter: Filter?
    
    var body: some View {
        FilterAddView(interactionType: interactionType, filter: filter, onAdd: saveFilter)
    }
}

struct FilterAddContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterAddContainerView(interactionType: .add)
    }
}

extension FilterAddContainerView {
    
    private func saveFilter(filter: Filter) {
        let action: FilterAction = interactionType == .add ? .add(filter: filter) : .update(filter: filter)
        store.dispatch(.filter(action: action))
    }
    
}
