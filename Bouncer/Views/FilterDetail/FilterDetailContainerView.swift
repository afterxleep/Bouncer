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
    var selectedDestination: FilterDestination

    @State private var filterType: FilterType
    @State var filterDestination: FilterDestination
    @State private var filterTerm: String
    @State private var exactMatch: Bool
    @State private var useRegex: Bool
    @State private var isCaseSensitive: Bool

    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        switch interactionType {
        case .add:
            FilterDetailView(title: "FILTER_ADD_VIEW_TITLE",
                             leadingBarItem: cancelButton,
                             trailingBarItem: saveButton,
                             filterType: $filterType,
                             filterDestination: $filterDestination,
                             filterTerm: $filterTerm,
                             exactMatch: $exactMatch,
                             useRegex: $useRegex,
                             isCaseSensitive: $isCaseSensitive)
        case .update:
            FilterDetailView(isEmbedded: false,
                             title: "FILTER_EDIT_VIEW_TITLE",
                             leadingBarItem: cancelButton.hidden(),
                             trailingBarItem: saveButton,
                             filterType: $filterType,
                             filterDestination: $filterDestination,
                             filterTerm: $filterTerm,
                             exactMatch: $exactMatch,
                             useRegex: $useRegex,
                             isCaseSensitive: $isCaseSensitive)
        }
    }
    
}

extension FilterDetailContainerView {
    
    init(interactionType: InteractionType = .add, filter: Filter? = nil, selectedDestination: FilterDestination = .junk) {
        self.interactionType = interactionType
        self.filterId = filter?.id
        self.selectedDestination = selectedDestination
        self._filterType = .init(initialValue: filter?.type ?? .any)
        self._filterTerm = .init(initialValue: filter?.phrase ?? "")
        let action = filter?.subAction != FilterDestination.none && filter?.subAction != nil ? filter?.subAction : selectedDestination
        self._filterDestination = .init(initialValue: action ?? .junk)
        self._exactMatch = .init(initialValue: false)
        self._useRegex = .init(initialValue: filter?.useRegex ?? false)
        self._isCaseSensitive = .init(initialValue: filter?.caseSensitive ?? false)
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
        var action: FilterDestination
        var subAction: FilterDestination
        switch filterDestination {
        case .promotion, .promotionOffers, .promotionCoupons, .promotionOther:
            action = .promotion
            subAction = filterDestination
        case .transaction, .transactionOrder, .transactionFinance, .transactionReminders, .transactionHealth, .transactionOther:
            action = .transaction
            subAction = filterDestination
        case .junk:
            action = .junk
            subAction = .none
        case .none:
            action = .none
            subAction = .none
        case .allow:
            action = .allow
            subAction = .allow
        }
        let filter = Filter(id: filterId ?? UUID(),
                            phrase: filterTerm.trimmed,
                            type: filterType,
                            action: action,
                            subAction: subAction,
                            useRegex: useRegex,
                            caseSensitive: isCaseSensitive)
        return filter
    }
    
}

struct FilterDetailContainerView_Previews: PreviewProvider {
    static var previews: some View {
        FilterDetailContainerView()
    }
}
