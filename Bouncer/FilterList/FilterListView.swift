//
//  FilterListView.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import SwiftUI

extension FilterType {
    var listDescription: (image: String, color: Color) {
        switch self {
        case .any:
            return ("message", Color.green)
        case .sender:
            return ("person", Color.blue)
        case .message:
            return ("text.quote", Color.pink)
        }
    }
}

extension FilterAction {
    var listDescription: (image: String, color: Color, text: LocalizedStringKey) {
        switch self {
        case .junk:
            return ("bin.xmark", Color.red, "JUNK_ACTION")
        case .transaction:
            return ("arrow.right.arrow.left", Color.blue, "TRANSACTION_ACTION")
        case .promotion:
            return ("tag", Color.green, "PROMOTION_ACTION")
        }
    }
}


struct FilterListView: View {
    @StateObject var viewModel = FilterViewModel()
    @State private var showingSettings = false
    @State private var showingAddForm = false
    
    func getFilterTypeDecoration(filter: Filter) -> (image: String, color: Color) {
        var data: (image: String, color: Color)
        switch(filter.type) {
            case .sender:
                data = FilterType.sender.listDescription
            case .message:
                data = FilterType.message.listDescription
            default:
                data = FilterType.any.listDescription
        }
        return (data.image, data.color)
    }
    
    func getFilterActionDecoration(filter: Filter) -> (image: String, color: Color, text: LocalizedStringKey) {
        var data: (image: String, color: Color, text: LocalizedStringKey)
        switch (filter.action) {
            case .junk:
                data = FilterAction.junk.listDescription
            case .promotion:
                data = FilterAction.promotion.listDescription
            case .transaction:
                data = FilterAction.transaction.listDescription
            }
            return (data.image, data.color, data.text)
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
                                let typeDecoration = getFilterTypeDecoration(filter: item)
                                let actionDecoration = getFilterActionDecoration(filter: item)
                                HStack(spacing: 10) {
                                    Image(systemName: typeDecoration.image)
                                        .foregroundColor(typeDecoration.color)
                                        .aspectRatio(contentMode: .fit)
                                    Text("'\(item.phrase)'")
                                            .bold()
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: actionDecoration.image)
                                        Text(actionDecoration.text)
                                    }
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .foregroundColor(.gray)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray, lineWidth: 1)
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
                                Image(systemName: "questionmark.circle").imageScale(.large)
                            }
                            .sheet(isPresented: $showingSettings) {
                                TutorialView(firstLaunch: false)                                    
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
