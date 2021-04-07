//
//  FilterDetailContainerView.swift
//  Bouncer
//

import SwiftUI

enum InteractionType: Equatable {
    case add
    case update
}

struct FilterDetailContainerView: View {
    
    var interactionType: InteractionType
    var filterId: UUID?
    
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var filterType: FilterType
    @State private var filterDestination: FilterDestination
    @State private var filterTerm: String
    @State private var exactMatch: Bool
    
    var body: some View {
        switch interactionType {
        case .add:
            FilterDetailView(title: "FILTER_ADD_VIEW_TITLE",
                             leadingBarItem: cancelButton,
                             trailingBarItem: saveButton,
                             filterType: $filterType,
                             filterDestination: $filterDestination,
                             filterTerm: $filterTerm,
                             exactMatch: $exactMatch)
        case .update:
            FilterDetailView(isEmbedded: false,
                             title: "FILTER_EDIT_VIEW_TITLE",
                             leadingBarItem: cancelButton.hidden(),
                             trailingBarItem: saveButton,
                             filterType: $filterType,
                             filterDestination: $filterDestination,
                             filterTerm: $filterTerm,
                             exactMatch: $exactMatch)
        }
    }
    
}

extension FilterDetailContainerView {
    
    init(interactionType: InteractionType = .add, filter: Filter? = nil) {
        self.interactionType = interactionType
        self.filterId = filter?.id
        self._filterType = .init(initialValue: filter?.type ?? .any)
        self._filterTerm = .init(initialValue: filter?.phrase ?? "")
        self._filterDestination = .init(initialValue: filter?.action ?? .junk)
        self._exactMatch = .init(initialValue: false)
    }
    
    private var cancelButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("CANCEL")
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            if(!filterTerm.isBlank) {
                saveFilter()
                presentationMode.wrappedValue.dismiss()
            }
        })
        {
            Text("SAVE").disabled(filterTerm.isBlank)
        }
    }
    
    private func saveFilter() {
        let action: FilterAction = interactionType == .add ? .add(filter: filterToSave) : .update(filter: filterToSave)
        store.dispatch(.filter(action: action))
    }
    
    
    private var filterToSave: Filter {
        Filter(id: filterId ?? UUID(),
               phrase: filterTerm.trimmed,
               type: filterType,
               action: filterDestination)
    }
    
}

struct FilterDetailContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterDetailContainerView()
    }
}
