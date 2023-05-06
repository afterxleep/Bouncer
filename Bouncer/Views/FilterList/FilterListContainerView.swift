//
//  FilterListContainerView.swift
//  Bouncer
//

import SwiftUI

enum FilterListError: Identifiable {
    case emptyImportFileError
    case decodingError(String)
    case unknownError(String)

    var id: String {
        switch self {
            case .emptyImportFileError: return "EMPTY_IMPORT_FILE"
            case .decodingError(let str): return str
            case .unknownError(let str): return str
        }
    }

    var textView: Text {
        switch self {
            case .emptyImportFileError: return Text("EMPTY_IMPORT_FILE")
            case .decodingError(let str): return Text("IMPORT_ERROR \(str)")
            case .unknownError(let str): return Text("IMPORT_ERROR \(str)")
        }
    }
}

struct FilterListContainerView: View {
    @EnvironmentObject var store: AppStore

    @State var shouldShowImportList: Bool = false
    @State var shouldDisplayErrorMessage: Bool = false
    @State var errorAlert: FilterListError? = nil
    var errorMessage: String = ""

    var body: some View {
        FilterListView(filters: store.state.filters.filters,
                       onDelete: deleteFilter,
                       onImport: importFilters,
                       importFiltersFromURL: importFiltersFromURL,
                       openSettings: {},
                       showError: showError(error:),
                       shouldShowImportList: $shouldShowImportList
        )
            // Display Filter import dialog when needed
            .onChange(of: store.state.filters.filterImportInProgress, perform: { status in
                // Add a little delay to allow the File Selection view to dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shouldShowImportList = status // Delay setting isPresented to false
                }
            })

            // Import Error Display
            .alert(item: $errorAlert) { error in
                Alert(title: Text("ERROR"), message: error.textView)
            }
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

    func showError(error: FilterListError) {
        errorAlert = error
    }

}
