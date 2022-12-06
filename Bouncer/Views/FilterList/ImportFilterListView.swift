//
//  ImportFilterListView.swift
//  Bouncer
//

import SwiftUI

struct ImportFilterListView: View {
    var existingFilters: [Filter]
    var filters: [Filter]
    let onAdd: ([Filter]) -> Void
    let onCancel: () -> Void
    
    private var newFilters: [Filter]
    private var duplicateFilters: [Filter]

    @State private var selectedFilters: Set<Filter> = Set()
    
    init(existingFilters: [Filter], filters: [Filter], onAdd: @escaping ([Filter]) -> Void, onCancel: @escaping () -> Void) {
        self.existingFilters = existingFilters
        self.filters = filters
        
        self.newFilters = self.filters.filter { !existingFilters.contains($0) }
        self.duplicateFilters = self.filters.filter { existingFilters.contains($0) }
        
        self.onAdd = onAdd
        self.onCancel = onCancel
        self._selectedFilters = .init(initialValue: Set(self.newFilters))
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            NavigationView {
                filterList
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button {
                                self.onCancel()
                            } label: {
                                Image(systemName: SYSTEM_IMAGES.CLOSE.image)
                            }
                        }
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    self.selectedFilters = Set(filters)
                                } label: {
                                    Label("SELECT_ALL", systemImage: SYSTEM_IMAGES.SELECT_ALL.image)
                                }
                                Button {
                                    self.selectedFilters = Set(self.newFilters)
                                } label: {
                                    Label("SELECT_NEW", systemImage: SYSTEM_IMAGES.SELECT_NEW.image)
                                }
                                Button {
                                    self.selectedFilters = Set()
                                } label: {
                                    Label("SELECT_NONE", systemImage: SYSTEM_IMAGES.SELECT_NONE.image)
                                }
                            } label: {
                                Image(systemName: SYSTEM_IMAGES.CHECKLIST_OPTIONS.image)
                            }

                            Button {
                                self.onAdd(Array(self.selectedFilters))
                            } label: {
                                Image(systemName: SYSTEM_IMAGES.ADD.image)
                            }
                        }
                    }
            }
        }
    }
}

struct ImportFilterListView_Previews: PreviewProvider {
    static var previews: some View {
        ImportFilterListView(existingFilters: [], filters: [], onAdd: {_ in }, onCancel: {})
    }
}

extension ImportFilterListView {

    var filterList: some View {
        VStack {
            List {
                Section("NEW_FILTERS") {
                    ForEach(newFilters) { filter in
                        filterRowView(filter,
                                      selected: self.selectedFilters.contains(filter),
                                      duplicate: false)
                    }
                }
                
                Section("DUPLICATE_FILTERS") {
                    ForEach(duplicateFilters) { filter in
                        filterRowView(filter,
                                      selected: self.selectedFilters.contains(filter),
                                      duplicate: true)
                    }
                }
            }.listStyle(.plain)
        }
    }
    
    @ViewBuilder func filterRowView(_ filter: Filter, selected: Bool, duplicate: Bool) -> some View {
        let systemImage = selected ? SYSTEM_IMAGES.ROW_CHECKED : SYSTEM_IMAGES.ROW_UNCHECKED
        
        Button {
            if (selected) {
                self.selectedFilters.remove(filter)
            } else {
                self.selectedFilters.insert(filter)
            }
        } label: {
            VStack {
                HStack {
                    Image(systemName: systemImage.image).foregroundColor(systemImage.color).imageScale(.large)
                    FilterRowView(filter: filter)
                }
            }
        }.listRowBackground(selected ? systemImage.color.opacity(0.15) : nil)
    }
    
}
