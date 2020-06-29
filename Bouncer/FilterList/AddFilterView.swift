//
//  AddFilterView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct AddFilterView: View {
    
    enum LocalizedString: LocalizedStringKey {
        case selectAFilterType = "Filter using:"
        case enterWordOrPhrase = "Enter a word or Phrase to filter"
        case addFilter = "Add Filter"
        case save = "Save"
        case cancel = "Cancel"
        case advanced = "Advanced"
        case exactMatch = "Exact Match"
        case exactMatchExplanationSender = "Filter messages only when the sender exactly matches the provided word or phrase."
        case exactMatchExplanationBody = "Filter messages only when the text exactly matches the provided word or phrase."
        case filterInformation = "Filter Information"
        case sender = "sender"
        case body = "body"
    }
    
    enum FilterOption: LocalizedStringKey, Equatable, CaseIterable {
        case senderAndMessage = "Sender and Text"
        case senderOnly = "Sender"
        case messageOnly = "Text"
    }
    
    @Binding var showingAddForm :Bool
    @State var filterOption: FilterOption = .senderAndMessage
    @State var filterTerm: String = ""
    @State var exactMatch: Bool = false
    @EnvironmentObject var appSettings: UserSettingsDefaults
    var viewModel: FilterListViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedString.filterInformation.rawValue)) {
                    Picker(LocalizedString.selectAFilterType.rawValue, selection: $filterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }.pickerStyle(DefaultPickerStyle())
                    TextField(LocalizedString.enterWordOrPhrase.rawValue, text: $filterTerm)
                        .autocapitalization(.none)
                        .disableAutocorrection(.none)
                        
                }
                if(filterOption != FilterOption.senderAndMessage) {
                    Section(header: Text(LocalizedString.advanced.rawValue),
                            footer: Text(filterOption == FilterOption.senderOnly ? LocalizedString.exactMatchExplanationSender.rawValue : LocalizedString.exactMatchExplanationBody.rawValue)) {
                        Toggle(isOn: $exactMatch, label: {
                            Text(LocalizedString.exactMatch.rawValue)
                        })
                    }
                }
            }
            .navigationTitle(LocalizedString.addFilter.rawValue)
            .navigationBarItems(
                leading:
                    Button(
                        action: {
                            self.showingAddForm = false
                        }) {
                        Text(LocalizedString.cancel.rawValue)
                },
                trailing:
                    Button(
                        action: {saveFilter()}) {
                        Text(LocalizedString.save.rawValue)
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
        viewModel.add(type: ruleTypeFrom(filterOption: filterOption),
                            phrase: filterTerm,
                            exactMatch: exactMatch)
 
        self.showingAddForm = false
    }
}


struct AddFilterView_Previews: PreviewProvider {
    static var viewModel = FilterListViewModel()
    static var previews: some View {
        AddFilterView(showingAddForm: .constant(true), viewModel: viewModel)
    }
}
