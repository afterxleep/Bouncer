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
    let userSettingsService: UserSettings = UserSettings()
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
        
        migrateFromV1()
    }
        
    func add(type: FilterType, phrase: String, action: FilterAction) {
        filterListService.add(filter: Filter(id: UUID(), phrase: phrase, type: type, action: action))
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
    
    func migrateFromV1() {
        filterListService.migrateFromV1()
    }

        
}


