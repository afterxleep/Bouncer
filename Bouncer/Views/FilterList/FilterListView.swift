//
//  FilterListView.swift
//  Bouncer
//

import SwiftUI

struct FilterListView: View {
    var filters: [Filter]
    var requiresPurchase: (() -> Bool)
    let onDelete: (IndexSet) -> Void
    let openSettings: () -> Void    

    @State var showingSettings = false
    @State var showingAddForm = false
    @State var showingInApp = false

    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                filterList
                .navigationBarTitle("LIST_VIEW_TITLE")
                .navigationBarItems(leading: helpButton, trailing: addButton)
            }
        }
    }
}



struct FilterListView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListView(filters: [],
                       requiresPurchase: { return false },
                       onDelete: {_ in },
                       openSettings: {}
        )
    }
}

extension FilterListView {

    var filterList: some View {
        Group {
            if(filters.count > 0) {
                List {
                    ForEach(filters) { filter in
                       FilterRowView(filter: filter)
                    }.onDelete(perform: onDelete )
                }
                .listStyle(PlainListStyle())
            } else {
                VStack(alignment: .center) {
                    Group() {
                        Text("EMPTY_LIST_TITLE").font(.title2).bold().padding()
                        Group {
                            Text("EMPTY_LIST_MESSAGE")
                            HStack(spacing: 0) {
                                Text("TAP_SPACE")
                                Image(systemName: "plus.circle")
                                Text("TO_ADD_A_FILTER_SPACE")
                            }
                        }.frame(width: 260)
                    }
                    .foregroundColor(Color("TextDefaultColor"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                }.padding(.bottom, 200)
            }
        }
    }

    var helpButton: some View {
        Group {
            Button(action: { showingSettings = true }) {
                Image(systemName: SYSTEM_IMAGES.HELP.image).imageScale(.large)
            }.sheet(isPresented: $showingSettings) {
                TutorialView(hasLaunchedApp: true, onSettingsTap: openSettings)
            }
        }
    }

    var addButton: some View {
        Group {
            if (requiresPurchase()) {
                Button(
                    action: { showingInApp = true }) {
                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                    }.sheet(isPresented: $showingInApp) {
                        UnlockAppView()
                    }
            } else {
                Button(
                    action: { showingAddForm = true }) {
                        Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
                    }.sheet(isPresented: $showingAddForm) {
                        FilterAddContainerView()
                    }
            }
        }
    }
}
