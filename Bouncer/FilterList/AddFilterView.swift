//
//  AddFilterView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

extension FilterType {
    var formDescription: (label: LocalizedStringKey, image: String, color: Color) {
        switch self {
        case .any:
            return ("SENDER_AND_TEXT", "message", Color.green)
        case .sender:
            return ("SENDER", "person", Color.blue)
        case .message:
            return ("TEXT", "text.quote", Color.pink)
        }
    }
}

extension FilterAction {
    var formDescription: (label: LocalizedStringKey, image: String, color: Color) {
        switch self {
        case .junk:
            return ("JUNK_ACTION", "bin.xmark", Color.red)
        case .transaction:
            return ("TRANSACTION_ACTION", "arrow.right.arrow.left", Color.blue)
        case .promotion:
            return ("PROMOTION_ACTION", "tag", Color.green)
        }
    }
}

struct AddFilterView: View {
    
     
    @Binding var showingAddForm :Bool
    @State var filterType: FilterType = .any
    @State var filterAction: FilterAction = .junk
    @State var filterTerm: String = ""
    @State var exactMatch: Bool = false    
    var viewModel: FilterListViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("FILTER_INFORMATION")) {
                    Picker("FILTER_TYPE_SELECTION_LABEL", selection: $filterType) {
                        ForEach(FilterType.allCases, id: \.self) { value in
                            HStack {
                                Image(systemName: value.formDescription.image).foregroundColor(value.formDescription.color)
                                Text(value.formDescription.label)
                            }
                        }
                    }.pickerStyle(DefaultPickerStyle())
                    HStack {
                        Text("CONTAINS_LABEL")
                        Spacer()
                        TextField("FILTER_ADD_TEXT_PLACEHOLDER", text: $filterTerm)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("FILTER_ACTION_LABEL", selection: $filterAction) {
                        ForEach(FilterAction.allCases, id: \.self) { value in
                            HStack {
                                Image(systemName: value.formDescription.image).foregroundColor(value.formDescription.color)
                                Text(value.formDescription.label)
                            }
                        }
                    }.pickerStyle(DefaultPickerStyle())
                }
            }
            .navigationBarTitle("FILTER_ADD_VIEW_TITLE")
            .navigationBarItems(
                leading:
                    Button(
                        action: {
                            self.showingAddForm = false
                        }) {
                        Text("CANCEL")
                },
                trailing:
                    Button(
                        action: {saveFilter()}) {
                        Text("SAVE")
                    }
            )
        }
    }
    
    func saveFilter() {
        if(filterTerm.count > 0) {            
            self.viewModel.add(type: filterType, phrase: filterTerm, action: filterAction)
            self.showingAddForm = false
        }
    }
}

struct AddFilterView_Previews: PreviewProvider {
    static var viewModel = FilterListViewModel()
    static var previews: some View {
        AddFilterView(showingAddForm: .constant(true), viewModel: viewModel)
    }
}
