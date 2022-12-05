//
//  ImportFilterListContainerView.swift
//  Bouncer
//

import SwiftUI

struct ImportFilterListContainerView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ImportFilterListView(
            existingFilters: store.state.filters.filters,
            filters: store.state.filters.filtersFromImport,
            onAdd: { filters in
                addFilters(filters: filters)
                doneImporting()
            },
            onCancel: doneImporting
        )
        .environmentObject(store)
    }
}

struct ImportFilterListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ImportFilterListContainerView()
    }
}

extension ImportFilterListContainerView {
    
    func addFilters(filters: [Filter]) {
        let existingFilters = store.state.filters.filters
        
        for f in filters {
            var filter = f
            // Prevent duplicate IDs
            if (existingFilters.contains(filter)) {
                filter = Filter(
                    id: UUID(),
                    phrase: filter.phrase,
                    type: filter.type,
                    action: filter.action,
                    subAction: filter.subAction,
                    useRegex: filter.useRegex
                )
            }
            store.dispatch(.filter(action: .add(filter: filter)))
        }
    }
    
    func doneImporting() {
        store.dispatch(.filter(action: .fetchFromImportComplete(filters: [])))
        self.dismiss()
    }
}
