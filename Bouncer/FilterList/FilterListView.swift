//
//  FilterListView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct FilterListView: View {
        
    @ObservedObject var viewModel = FilterListViewModel()
    @State private var showingSettings = false
    @State private var showingAddForm = false
    
    enum LocalizedStrings: LocalizedStringKey {
        case senderContains = "Sender contains: "
        case messageContains = "Text contains: "
        case senderIs = "Sender is: "
        case messageIs = "Text is: "
        case anyContains = "Anything contains: "
        case filters = "Filters"
    }
    
    func getFilterTypeString(filter: Filter) -> LocalizedStringKey {
        if(filter.exactMatch) {
            switch(filter.type) {
                case .sender:
                    return LocalizedStrings.senderIs.rawValue
                default:
                    return LocalizedStrings.messageIs.rawValue
            }
        }
        switch(filter.type) {
            case .sender:
                return LocalizedStrings.senderContains.rawValue
            case .message:
                return LocalizedStrings.messageContains.rawValue
            default:
                return LocalizedStrings.anyContains.rawValue
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                List {
                    ForEach(viewModel.filters) { item in
                        Text(getFilterTypeString(filter: item))
                            .italic()
                            .foregroundColor(.secondary)
                            .fontWeight(.regular)
                            +
                        Text("'\(item.phrase)'")
                            .bold()
                    }.onDelete(perform: deleteItems)
                }
                .listStyle(PlainListStyle())
                .navigationBarTitle(LocalizedStrings.filters.rawValue)
                .navigationBarItems(
                    leading:
                        Button(
                            action: { self.showingSettings = true }) {
                                Image(systemName: "gear").imageScale(.large)
                            }
                            .sheet(isPresented: $showingSettings) {
                                Text("Showing the settings window!")
                        },
                    trailing:
                        Button(
                            action: { self.showingAddForm = true }) {
                                Image(systemName: "plus.circle").imageScale(.large)
                            }
                            .sheet(isPresented: $showingAddForm) {
                                AddFilterView(showingAddForm: $showingAddForm)
                                    .environmentObject(viewModel)
                            }
                )
            }.accentColor(DESIGN.UI.DARK.ACCENT_COLOR)
        }
    }

    func deleteItems(at offsets: IndexSet) {
        viewModel.remove(at: offsets)
    }
}

struct FilterListView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListView()
    }
}
