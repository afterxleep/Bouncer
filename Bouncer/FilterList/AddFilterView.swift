//
//  AddFilterView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct AddFilterView: View {
        
    enum FilterOption: LocalizedStringKey, Equatable, CaseIterable {
        case senderAndMessage = "SENDER_AND_TEXT"
        case senderOnly = "SENDER"
        case messageOnly = "TEXT"
    }
    
    @Binding var showingAddForm :Bool
    @State var filterOption: FilterOption = .senderAndMessage
    @State var filterTerm: String = ""
    @State var exactMatch: Bool = false
    @EnvironmentObject var userSettings: UserSettings
    var viewModel: FilterListViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("FILTER_INFORMATION")) {
                    Picker("FILTER_TYPE_SELECTION_LABEL", selection: $filterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }.pickerStyle(DefaultPickerStyle())
                    TextField("FILTER_ADD_TEXT_PLACEHOLDER", text: $filterTerm)
                        .autocapitalization(.none)
                        .disableAutocorrection(.none)
                        
                }
                if(filterOption != FilterOption.senderAndMessage) {
                    Section(header: Text("ADVANCED"),
                            footer: Text("EXACT_MATCH_CAPTION")) {
                        Toggle(isOn: $exactMatch, label: {
                            Text("EXACT_MATCH")
                        })
                    }
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
    
    func ruleTypeFrom(filterOption: FilterOption) -> FilterType {
        switch(filterOption) {
            case .senderOnly:
                return .sender
            case .messageOnly:
                return .message
            default:
                return .any
        }
    }
    
    func saveFilter() {
        if(filterTerm.count > 0) {
            viewModel.add(type: ruleTypeFrom(filterOption: filterOption),
                                phrase: filterTerm,
                                exactMatch: exactMatch)
     
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
