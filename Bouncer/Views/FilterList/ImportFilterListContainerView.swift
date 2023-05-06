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
            filters: store.state.filters.importedFilters,
            onAdd: { filters in
                addFilters(filters: filters)
                doneImporting()
            },
            onCancel: doneImporting
        )
    }
}

struct ImportFilterListContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ImportFilterListContainerView()
    }
}

extension ImportFilterListContainerView {
    
    func addFilters(filters: [Filter]) {
        store.dispatch(.filter(action: .addMany(filters: filters)))
    }
    
    func doneImporting() {
        store.dispatch(.filter(action: .import(filters: [])))        
        self.dismiss()
    }
}
