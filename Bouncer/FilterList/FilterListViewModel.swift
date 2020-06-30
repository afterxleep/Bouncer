//
//  FilterListViewModel.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import Foundation
import Combine

final class FilterListViewModel: ObservableObject {
        
    enum strings: String {
        case blockList
        case remove
    }
    
    private var filterListView : FilterListView?
    let filterListService: FilterFileStore = FilterFileStore()
    let userSettingsService: UserSettingsDefaults = UserSettingsDefaults()
    var filterListcancellable: AnyCancellable?
    var defaultsCancellable: AnyCancellable?
    
    @Published var filters: [Filter] = []
    @Published var hasAddedFilters: Bool = true
    @Published var isFirstLaunch: Bool = false
    
    //MARK: - Initializer
    init() {
        filterListcancellable = filterListService
            .$filters
                .receive(on: RunLoop.main)
                .sink { [weak self] filters in
                    self?.filters = filters                    
                    self?.isFirstLaunch = (filters.count == 0 && self?.hasAddedFilters == false) ? true : false
                }
        
        defaultsCancellable = userSettingsService
            .$hasAddedFilters
                .receive(on: RunLoop.main)
                .sink { [weak self ] hasAddedFilters in
                    self?.hasAddedFilters = hasAddedFilters
                }
        
        migrateFromPreviousVersion()
        
    }
    
    func add(type: FilterType, phrase: String, exactMatch: Bool) {
        filterListService.add(filter: Filter(id: UUID(), type: type, phrase: phrase, exactMatch: exactMatch))
        userSettingsService.hasAddedFilters = true
    }
    
    func remove(at offsets: IndexSet) {
        for o in offsets {
            filterListService.remove(id: filters[o].id)
        }
    }
    
    func reset() {
        filterListService.reset()
    }
    
    func migrateFromPreviousVersion() {
        let store = FilterFileStore()
        store.migrateFromPreviousVersion()
    }

        
}


