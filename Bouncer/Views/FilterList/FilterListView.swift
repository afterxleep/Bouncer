//
//  FilterListView.swift
//  Bouncer
//

import SwiftUI

struct FilterListContainerView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {        
        FilterListView(
            filters: store.state.filters.filters,
            purchasedApp: false,
            onDelete: delete
        )
    }
    
    func delete(at indexes: IndexSet) {
        
        for o in indexes {
            let id = store.state.filters.filters[o].id
            //store.send(.filter(action: .remove(uuid: id)))
        }
    }
    
}

struct FilterListView: View {
    @State var filters: [Filter]
    @State var purchasedApp: Bool
    @State private var showingSettings = false
    @State private var showingAddForm = false
    @State private var showingInApp = false
    
    let onDelete: ((IndexSet) -> Void)?
    
    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                Group {
                    if(filters.count > 0) {
                        List {
                            ForEach(filters) { filter in
                               FilterRowView(filter: filter)
                            }.onDelete(perform: onDelete)
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
                            Image(systemName: SYSTEM_IMAGES.HELP.image).imageScale(.large)
                            }
                            .sheet(isPresented: $showingSettings) {
                                //TutorialView(firstLaunch: false)                                    
                        },
                    trailing:
                        Group {
                            if (purchasedApp) {
                                Button(
                                    action: { self.showingInApp = true }) {
                                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                                    }
                                    .sheet(isPresented: $showingInApp) {
                                        UnlockAppView()
                                    }
                            } else {
                                Button(
                                    action: { self.showingAddForm = true }) {
                                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                                    }
                                    .sheet(isPresented: $showingAddForm) {
                                       
                                    }
                            }
                        }                        
                )
            }            
            
        }
    }

}



struct FilterListView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListView(filters: [],
                       purchasedApp: false,
                       onDelete: nil
        )
    }
}
