//
//  FilterDetailView.swift
//  Bouncer
//

import SwiftUI

struct FilterDetailView<L: View, R: View>: View {
    
    var isEmbedded = true
    var title: String
    var leadingBarItem: L
    var trailingBarItem: R
    
    @Binding var filterType: FilterType
    @Binding var filterDestination: FilterDestination    
    @Binding var filterTerm: String
    @Binding var exactMatch: Bool
    @Binding var useRegex: Bool
    @Binding var isCaseSensitive: Bool
    
    var body: some View {
        rootView
    }
    
}

extension FilterDetailView {
    
    @ViewBuilder private var rootView: some View {
        if isEmbedded {
            NavigationView {
                form
                    .navigationBarTitle("NEW_FILTER")
                    .navigationBarItems(leading: leadingBarItem, trailing: trailingBarItem)
            }
        } else {
            form
                .navigationBarTitle("UPDATE_FILTER")
                .navigationBarItems(trailing: trailingBarItem)
        }
    }
    
    private func filterPickerSectionFor(_ filterDestination: FilterDestination) -> some View {
        HStack {
            Image(systemName: filterDestination.listDescription.decoration.image)
            Text(filterDestination.listDescription.text)            
        }
    }
    
    private var form: some View {
        Form {
            Section(header: Text("FILTER_INFORMATION")) {
                Picker(selection: $filterType, label: Text("FILTER_TYPE_SELECTION_LABEL")) {
                    ForEach(FilterType.allCases, id: \.self) { value in
                        VStack {
                            Text(value.formDescription.text)
                            Image(systemName: value.formDescription.decoration.image)
                        }
                    }
                }
                HStack {
                    Text("FILTER_CONTAINS_TEXT_LABEL")
                    Spacer()
                    TextField("FILTER_TEXT_PLACEHOLDER", text: $filterTerm)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.trailing)
                }
                Picker(selection: $filterDestination, label: Text("FILTER_ACTION_LABEL")) {
                    Section {
                        filterPickerSectionFor(.allow).tag(FilterDestination.allow)
                        filterPickerSectionFor(.junk).tag(FilterDestination.junk)
                    }
                    Section(header: Text("TRANSACTIONS")) {
                        filterPickerSectionFor(.transactionOrder).tag(FilterDestination.transactionOrder)
                        filterPickerSectionFor(.transactionFinance).tag(FilterDestination.transactionFinance)
                        filterPickerSectionFor(.transactionReminders).tag(FilterDestination.transactionReminders)
                        filterPickerSectionFor(.transactionOther).tag(FilterDestination.transactionOther)
                    }
                    Section(header: Text("PROMOTIONS")) {
                        filterPickerSectionFor(.promotionOffers).tag(FilterDestination.promotionOffers)
                        filterPickerSectionFor(.promotionCoupons).tag(FilterDestination.promotionCoupons)
                        filterPickerSectionFor(.promotionOther).tag(FilterDestination.promotionOther)
                    }
                }
            }
            Section(header: Text("ADVANCED")) {
                Toggle(isOn: $useRegex) {
                    VStack(alignment: .leading) {
                        Text("USE_REGULAR_EXPRESSIONS")
                            .padding(0)
                        Text("USE_REGULAR_EXPRESSIONS_DETAIL")
                            .font(.caption)
                            .foregroundColor(Color("TextDefaultColor"))
                    }.padding(.init(top: 5, leading: 0, bottom: 5, trailing: 10))
                }
                Toggle(isOn: $isCaseSensitive) {
                    VStack(alignment: .leading) {
                        Text("IS_CASE_SENSITIVE")
                            .padding(0)
                        Text("IS_CASE_SENSITIVE_DETAIL")
                            .font(.caption)
                            .foregroundColor(Color("TextDefaultColor"))
                    }.padding(.init(top: 5, leading: 0, bottom: 5, trailing: 10))
                }
            }
        }
    }
}

struct FilterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FilterDetailView(title: "Add Filter",
                         leadingBarItem: Text(""),
                         trailingBarItem: Text(""),
                         filterType: .constant(.any),
                         filterDestination: .constant(.transaction),
                         filterTerm: .constant("Query Term"),
                         exactMatch: .constant(false),
                         useRegex: .constant(false),
                         isCaseSensitive: .constant(false))
    }
}
