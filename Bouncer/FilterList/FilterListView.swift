//
//  FilterListView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct FilterListView: View {

    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var viewModel = FilterListViewModel()    
    @State private var showingSettings = false
    @State private var showingAddForm = false
    
    enum LocalizedStrings: LocalizedStringKey {
        case senderContains = "SENDER_CONTAINS_PREFFIX"
        case messageContains = "MESSAGE_CONTAINS_PREFFIX"
        case senderIs = "SENDER_IS_PREFFIX"
        case messageIs = "MESSAGE_IS_PREFFIX"
        case anyContains = "SENDER_OR_TEXT_CONTAINS_PREFFIX"
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
    
    var shouldDisplayList: Bool {        
        if(viewModel.filters.count > 0) {
            return true
        }
        return false
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                Group {
                    if(shouldDisplayList) {
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
                    } else {
                        EmptyListView()                        
                    }
                }
                .navigationBarTitle("LIST_VIEW_TITLE")
                .navigationBarItems(
                    leading:
                        Button(
                            action: {
                                self.showingSettings = true
                                
                            }) {
                                Image(systemName: "questionmark.circle").imageScale(.large)
                            }
                            .sheet(isPresented: $showingSettings) {
                                TutorialView(firstLaunch: false)
                                    .environmentObject(userSettings)
                        },
                    trailing:
                        Button(
                            action: { self.showingAddForm = true }) {
                                Image(systemName: "plus.circle").imageScale(.large)
                            }
                            .sheet(isPresented: $showingAddForm) {
                                AddFilterView(showingAddForm: $showingAddForm,
                                              viewModel: self.viewModel)
                            }
                )
            }            
            
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
