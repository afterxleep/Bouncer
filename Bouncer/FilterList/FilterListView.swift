//
//  FilterListView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct FilterListView: View {

    @EnvironmentObject var appSettings: UserSettingsDefaults
    @ObservedObject var viewModel = FilterListViewModel()    
    @State private var showingSettings = false
    @State private var showingAddForm = false
    
    enum LocalizedStrings: LocalizedStringKey {
        case senderContains = "Sender contains: "
        case messageContains = "Text contains: "
        case senderIs = "Sender is: "
        case messageIs = "Text is: "
        case anyContains = "Anything contains: "
        case filters = "Block List"
        case welcomeAlertTitle = "You're ready to go!"
        case welcomeAlertMessage = "Bouncer will use your block list to filter SMS messages from unknown senders and people not in your contact list."
        case gotIt = "Got it!"
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
        print(viewModel.filters.count)
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
                .navigationBarTitle(LocalizedStrings.filters.rawValue)
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
                                    .environmentObject(appSettings)
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
