//
//  FilterListView.swift
//  Bouncer
//

import SwiftUI
import UniformTypeIdentifiers
import os.log

struct FilterListView: View {
    var filters: [Filter]
    let onDelete: (UUID) -> Void
    let onImport: ([Filter]) -> Void
    let importFiltersFromURL: (URL) -> Void
    let openSettings: () -> Void
    let showError: (FilterError) -> Void
    @Binding var shouldShowImportList: Bool

    @State var showingSettings = false
    @State var showingFilterDetail = false
    @State var showingInApp = false
    @State var showingFileImporter = false
    @State private var searchText = ""
    @State private var selectedFilterType = FilterDestination.junk

    var filteredFilters: [Filter] {
        switch selectedFilterType {
            case .allow:
                return filters.filter { $0.action == .allow }
            case .junk:
                return filters.filter { $0.action == .junk }
            default:
                return filters.filter { $0.action != .junk && $0.action != .allow }
        }
    }

    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                ZStack {
                    emptyMessage
                    VStack {
                        picker
                        filterList
                            .navigationBarTitle("LIST_VIEW_TITLE")
                            .toolbar {
                                ToolbarItemGroup(placement: .navigationBarLeading) {
                                    menu
                                }
                                ToolbarItemGroup(placement: .navigationBarTrailing) {
                                    addButton
                                }
                            }                            
                    }
                }

            }.searchable(text: $searchText, prompt: Text("SEARCH"))
        }
    }
}

struct FilterListView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListView(filters: [],
                       onDelete: {_ in },
                       onImport: {_ in },
                       importFiltersFromURL: { _ in },
                       openSettings: {},
                       showError: { _ in },
                       shouldShowImportList: .constant(false)
        )
    }
}

extension FilterListView {

    var picker: some View {
        Picker("", selection: $selectedFilterType) {
            Image(systemName: SYSTEM_IMAGES.ALLOW.image).tag(FilterDestination.allow)
            Image(systemName: SYSTEM_IMAGES.SPAM.image).tag(FilterDestination.junk)
            Image(systemName: SYSTEM_IMAGES.PROMOTION.image).tag(FilterDestination.promotionOther)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.all)
        .accentColor(COLORS.DEFAULT_COLOR)
    }

    @ViewBuilder
    var emptyMessage: some View {
        if filteredFilters.count == 0 {
            VStack(alignment: .center) {
                Group() {
                    emptyListTitle.font(.title2).bold().padding()
                    Group {
                        emptyListMessage.padding(.bottom, 10)
                        HStack(spacing: 0) {
                            Text("TAP_SPACE")
                            Image(systemName: "plus.circle")
                            Text("TO_ADD_A_FILTER_SPACE")
                        }
                    }.frame(width: 260)
                }
                .foregroundColor(Color("TextDefaultColor"))
                .multilineTextAlignment(.center)

            }.padding(.bottom, 10)
            Spacer().padding(.bottom, 100)
        }
        }


    var filterList: some View {
        VStack {
            List {
                let filters = filteredFilters.filter {
                    searchText.isEmpty ||
                    $0.phrase.localizedCaseInsensitiveContains(searchText)
                }
                ForEach(filters) { filter in
                    NavigationLink(destination: FilterDetailContainerView(interactionType: .update,
                                                                          filter: filter)) {
                        FilterRowView(filter: filter)
                    }
                }.onDelete { indices in
                    for index in indices {
                        let deletedItem = filters[index]                        
                        onDelete(deletedItem.id)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                do {
                    importFiltersFromURL(url)
                }
            case .failure(let error):
                showError(.unknownError(error.localizedDescription))
            }
        }
        .sheet(isPresented: $shouldShowImportList) {
            ImportFilterListContainerView()
        }.sheet(isPresented: $showingSettings) {
            TutorialContainerView()
        }
    }
    
    var helpButton: some View {
        Group {
            Button(action: { showingSettings = true }) {
                Label("HELP", systemImage: SYSTEM_IMAGES.HELP.image).imageScale(.large)
            }
        }
    }
    
    var addButton: some View {
        Group {
            Button(
                action: { showingFilterDetail = true }) {
                Image(systemName: SYSTEM_IMAGES.ADD.image).imageScale(.large)
            }.sheet(isPresented: $showingFilterDetail) {
                FilterDetailContainerView(selectedDestination: selectedFilterType)
            }
        }
    }
    
    var menu: some View {
        Menu {
            Button(action: { showingFileImporter = true }) {
                Label("IMPORT_BLOCK_LIST", systemImage: SYSTEM_IMAGES.IMPORT.image).imageScale(.large)
            }
            if let filterStoreFileURL = FilterStoreFile.fileURL {
                ShareLink(item: filterStoreFileURL) {
                    Label("EXPORT_BLOCK_LIST", systemImage: SYSTEM_IMAGES.EXPORT.image).imageScale(.large)
                }
            }
            Divider()
            helpButton            
        } label: {
            Image(systemName: SYSTEM_IMAGES.IMPORT_EXPORT_MENU.image).imageScale(.large)
        }
    }

    @ViewBuilder
    var emptyListTitle: some View {
        switch selectedFilterType {
            case .allow:
                Text("EMPTY_LIST_ALLOW_TITLE")
            case .junk:
                Text("EMPTY_LIST_JUNK_TITLE")
            default:
                Text("EMPTY_LIST_OTHER_TITLE")
        }
    }

    @ViewBuilder
    var emptyListMessage: some View {
        switch selectedFilterType {
            case .allow:
                Text("EMPTY_LIST_ALLOW_MESSAGE")
            case .junk:
                Text("EMPTY_LIST_JUNK_MESSAGE")
            default:
                Text("EMPTY_LIST_OTHER_MESSAGE")
        }
    }
}
