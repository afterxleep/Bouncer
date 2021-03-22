//
//  FilterDetailContainerView.swift
//  Bouncer
//

import SwiftUI

struct FilterDetailContainerView: View {
    @EnvironmentObject var store: AppStore
    var interactionType: InteractionType = .add
    var filter: Filter?
    
    var body: some View {
        FilterDetailView(interactionType: interactionType, filter: filter, onSave: saveFilter)
    }
}

struct FilterDetailContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterDetailContainerView(interactionType: .add)
    }
}

extension FilterDetailContainerView {
    
    private func saveFilter(filter: Filter) {
        let action: FilterAction = interactionType == .add ? .add(filter: filter) : .update(filter: filter)
        store.dispatch(.filter(action: action))
    }
    
}
