//
//  AddFilterView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct AddFilterView: View {
    @Binding var showingAddForm :Bool
    @State var filterType: FilterType = .any
    @State var filterAction: FilterAction = .junk
    @State var filterTerm: String = ""
    @State var exactMatch: Bool = false    
    var viewModel: FilterViewModel
    
    var body: some View {
        NavigationView {
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
                                Image(systemName: value.formDescription.decoration.image).foregroundColor(value.formDescription.decoration.color)
                                Text(value.formDescription.text)
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
    static var viewModel = FilterViewModel()
    static var previews: some View {
        AddFilterView(showingAddForm: .constant(true), viewModel: viewModel)
    }
}
