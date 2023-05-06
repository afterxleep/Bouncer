//
//  FilterListContainerView.swift
//  Bouncer
//

import SwiftUI

struct FilterListContainerView: View {
    @EnvironmentObject var store: AppStore

    @State var shouldShowImportList: Bool = false

    var body: some View {
        FilterListView(filters: store.state.filters.filters,
                       onDelete: deleteFilter,
                       onImport: importFilters,
                       importFiltersFromURL: importFiltersFromURL,
                       openSettings: {},
                       shouldShowImportList: $shouldShowImportList)

            // Display Filter import dialog when needed
            .onChange(of: store.state.filters.filterImportInProgress, perform: { status in
                shouldShowImportList = status
            })
    }
}

struct FilterListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListContainerView()
    }
}

extension FilterListContainerView {

    func deleteFilter(at offsets: IndexSet) {
        for o in offsets {
            store.dispatch(.filter(action: .delete(uuid: store.state.filters.filters[o].id)))
        }
    }
    
    func importFilters(filters: [Filter]) {
        let action: FilterAction = .import(filters: filters)
        store.dispatch(.filter(action: action))
    }

    func importFiltersFromURL(url: URL) {
        let action: FilterAction = .loadFromURL(url: url)
        store.dispatch(.filter(action: action))
    }

}
