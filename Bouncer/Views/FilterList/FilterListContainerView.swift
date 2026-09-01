//
//  FilterListContainerView.swift
//  Bouncer
//

import SwiftUI

enum FilterError: Identifiable {
    case emptyImportFileError
    case decodingFailed(reason: String)
    case loadFailed
    case saveFailed
    case deleteFailed
    case diskError(message: String)
    case invalidRegex(String)

    /// Stable identifier used for tests, analytics, and any external caller
    /// comparing errors. Localised strings live in en.lproj / es.lproj with
    /// identical key sets.
    var id: String {
        switch self {
        case .emptyImportFileError:  return "ERROR_EMPTY_IMPORT_FILE"
        case .decodingFailed:        return "ERROR_DECODING_FAILED"
        case .loadFailed:            return "ERROR_LOAD_FAILED"
        case .saveFailed:            return "ERROR_SAVE_FAILED"
        case .deleteFailed:          return "ERROR_DELETE_FAILED"
        case .diskError:             return "ERROR_DISK"
        case .invalidRegex(let str): return "ERROR_INVALID_REGEX_\(str)"
        }
    }

    /// The user-facing message. Every case resolves to a localised string key
    /// that exists in both en.lproj and es.lproj.
    var localizedMessage: String {
        switch self {
        case .emptyImportFileError:
            return NSLocalizedString("ERROR_EMPTY_IMPORT_FILE", comment: "")
        case .decodingFailed:
            return NSLocalizedString("ERROR_DECODING_FAILED", comment: "")
        case .loadFailed:
            return NSLocalizedString("ERROR_LOAD_FAILED", comment: "")
        case .saveFailed:
            return NSLocalizedString("ERROR_SAVE_FAILED", comment: "")
        case .deleteFailed:
            return NSLocalizedString("ERROR_DELETE_FAILED", comment: "")
        case .diskError(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString("ERROR_DISK %@", comment: ""),
                message
            )
        case .invalidRegex(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString("ERROR_INVALID_REGEX %@", comment: ""),
                message
            )
        }
    }

    /// For the alert, which needs a `Text`.
    var textView: Text { Text(localizedMessage) }
}

struct FilterListContainerView: View {
    @EnvironmentObject var store: AppStore

    @State var shouldShowImportList: Bool = false

    var errorBinding: Binding<FilterError?> {
        Binding(
            get: { store.state.filters.filterError },
            set: { _ in
                let action: FilterAction = .clearError
                store.dispatch(.filter(action: action))
            })}

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
            .alert(item: errorBinding) { error in
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

    func deleteFilter(id: UUID) {
        store.dispatch(.filter(action: .delete(uuid: id)))

    }
    
    func importFilters(filters: [Filter]) {
        let action: FilterAction = .import(filters: filters)
        store.dispatch(.filter(action: action))
    }

    func importFiltersFromURL(url: URL) {
        let action: FilterAction = .loadFromURL(url: url)
        store.dispatch(.filter(action: action))
    }

    func showError(error: FilterError) {
        Self.show(error, on: store)
    }

    /// Routes a view-level `FilterError` through the same `.error` action the
    /// reducer and `FilterDetailContainerView` use. Extracted as a static
    /// helper so the file-import failure path can be exercised from a unit
    /// test: the pre-fix `showError` set an unread `@State` and the alert
    /// never appeared.
    static func show(_ error: FilterError, on store: AppStore) {
        store.dispatch(.filter(action: .error(error)))
    }

}
