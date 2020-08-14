//
//  FilterAddView.swift
//  Bouncer
//

import SwiftUI

struct FilterAddView: View {
    var onAdd: (Filter) -> Void

    @Environment(\.presentationMode) var presentationMode
    @State var filterType: FilterType = .any
    @State var filterDestination: FilterDestination = .junk
    @State var filterTerm: String = ""
    @State var exactMatch: Bool = false

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
                    Picker("FILTER_ACTION_LABEL", selection: $filterDestination) {
                        ForEach(FilterDestination.allCases, id: \.self) { value in
                            HStack {
                                Image(systemName: value.formDescription.decoration.image).foregroundColor(value.formDescription.decoration.color)
                                Text(value.formDescription.text)
                            }
                        }
                    }.pickerStyle(DefaultPickerStyle())
                }
            }
            .navigationBarTitle("FILTER_ADD_VIEW_TITLE")
            .navigationBarItems(leading: cancelButton, trailing: saveButton)
        }
    }
}

struct FilterAddView_Previews: PreviewProvider {
    static var previews: some View {
        FilterAddView(onAdd: {_ in })
    }
}

extension FilterAddView {

    var cancelButton: some View {
        Button(
            action: {
                presentationMode.wrappedValue.dismiss()
            }) {
            Text("CANCEL")
        }
    }

    var saveButton: some View {
        Button(
            action: {
                onAdd(Filter(id: UUID() , phrase: filterTerm, type: filterType, action: filterDestination))
                self.presentationMode.wrappedValue.dismiss()
            }
        ) {
            Text("SAVE")
        }
    }
}
