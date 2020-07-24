//
//  FilterListView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

struct FilterListView: View {
    @StateObject var viewModel = FilterViewModel()
    @EnvironmentObject var store: AppStore
    @State private var showingSettings = false
    @State private var showingAddForm = false
    @State private var showingInApp = false
    
    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                Group {
                    if(viewModel.shouldDisplayList) {
                        List {
                            ForEach(store.state.filter.list) { item in
                                let typeDecoration = viewModel.getFilterTypeDecoration(filter: item)
                                let actionDecoration = viewModel.getFilterDestinationDecoration(filter: item)
                                HStack(spacing: 10) {
                                    Image(systemName: typeDecoration.image)
                                        .foregroundColor(.gray)
                                        .aspectRatio(contentMode: .fit)
                                    Text("'\(item.phrase)'")
                                            .bold()
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: actionDecoration.decoration.image)
                                        Text(actionDecoration.text)
                                    }
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .foregroundColor(Color.red)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.red, lineWidth: 1)
                                        )
                                }.padding(.vertical, 8)
                                .font(.headline)
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
                            Image(systemName: SYSTEM_IMAGES.HELP.image).imageScale(.large)
                            }
                            .sheet(isPresented: $showingSettings) {
                                TutorialView(firstLaunch: false)                                    
                        },
                    trailing:
                        Group {
                            if (viewModel.shouldDisplayInApp) {
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
                                        AddFilterView(showingAddForm: $showingAddForm,
                                                      viewModel: self.viewModel)
                                    }
                            }
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
