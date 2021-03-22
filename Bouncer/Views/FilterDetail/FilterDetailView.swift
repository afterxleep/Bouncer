//
//  FilterDetailView.swift
//  Bouncer
//

import SwiftUI

enum InteractionType: Equatable {
    case add
    case update
}

struct FilterDetailView: View {
    
    var onSave: (Filter) -> Void
    var interactionType: InteractionType
    var filter: Filter?
    
    @Environment(\.presentationMode) var presentationMode
    @State var filterType: FilterType
    @State var filterDestination: FilterDestination
    @State var filterTerm: String
    @State var exactMatch: Bool
    
    var body: some View {
        switch interactionType {
        case .add:
            NavigationView {
                form
                    .navigationBarTitle("FILTER_ADD_VIEW_TITLE")
                    .navigationBarItems(leading: cancelButton, trailing: saveButton)
            }
        case .update:
            form
                .navigationBarTitle("FILTER_EDIT_VIEW_TITLE")
                .navigationBarItems(trailing: saveButton)
        }
    }
    
}

struct FilterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FilterDetailView(interactionType: .add, onSave: {_ in })
    }
}

extension FilterDetailView {
    
    init(interactionType: InteractionType, filter: Filter? = nil, onSave: @escaping (Filter) -> Void) {
        self.filter = filter
        self._filterType = .init(initialValue: filter?.type ?? .any)
        self._filterTerm = .init(initialValue: filter?.phrase ?? "")
        self._filterDestination = .init(initialValue: filter?.action ?? .junk)
        self._exactMatch = .init(initialValue: false)
        self.interactionType = interactionType
        self.onSave = onSave
    }
    
    private var cancelButton: some View {
        Button(
            action: {
                presentationMode.wrappedValue.dismiss()
            }) {
            Text("CANCEL")
        }
    }
    
    private var saveButton: some View {
        Button(
            action: {
                if(filterTerm.count > 0) {
                    onSave(filterToSave)
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        ) {
            Text("SAVE").disabled(filterTerm.count == 0)
        }
    }
    
    private var filterToSave: Filter {
        Filter(id: filter?.id ?? UUID(),
               phrase: filterTerm,
               type: filterType,
               action: filterDestination)
    }
    
    private var form: some View {
        Form {
            Section(header: Text("FILTER_INFORMATION")) {
                Picker("FILTER_TYPE_SELECTION_LABEL", selection: $filterType) {
                    ForEach(FilterType.allCases, id: \.self) { value in
                        HStack {
                            Image(systemName: value.formDescription.decoration.image).foregroundColor(value.formDescription.decoration.color)
                            Text(value.formDescription.text)
                        }
                    }
                }.pickerStyle(DefaultPickerStyle())
                HStack {
                    Text("FILTER_CONTAINS_TEXT_LABEL")
                    Spacer()
                    TextField("FILTER_TEXT_PLACEHOLDER", text: $filterTerm)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.trailing)
                }
                Picker("FILTER_ACTION_LABEL", selection: $filterDestination) {
                    ForEach(FilterDestination.allCases, id: \.self) { value in
                        HStack {
                            Image(systemName: value.formDescription.decoration.image).foregroundColor(value.formDescription.decoration.color)
                            Text(value.formDescription.text)
                        }
                    }
                }
                .pickerStyle(DefaultPickerStyle())
            }
        }
    }
    
}
