//
//  FilterListViewModel.swift
//  Bouncer
//
//  Created by Daniel Bernal on 6/25/20.
//

import Foundation
import Combine
import SwiftUI


final class FilterViewModel: ObservableObject {
        
    enum strings: String {
        case blockList
        case remove
    }
    
    private var filterListView : FilterListView?
    let filterListService: FilterStore
    var appSettings: AppSettingsStore
    var ratingService: ReviewService
    var filterListcancellable: AnyCancellable?
    var defaultsCancellable: AnyCancellable?
    
    @Published var filters: [Filter] = []
    @Published var hasAddedFilters: Bool = true
    @Published var isFirstLaunch: Bool = false
    
    //MARK: - Initializer
    init(
        filterListService: FilterStore,
        appSettings: AppSettingsStore,
        ratingService: ReviewService) {
        
        self.filterListService = filterListService
        self.appSettings = appSettings
        self.ratingService = ratingService
        
        /*
        filterListcancellable = filterListService
            .filtersPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] filters in
                    self?.filters = filters
                }
         */
        
        migrateFromV1()
        saveHasLaunchedApp()
        requestReview()
    }
        
    func add(type: FilterType, phrase: String, action: FilterDestination) {
        filterListService.add(filter: Filter(id: UUID(), phrase: phrase, type: type, action: action))
    }
    
    func remove(at offsets: IndexSet) {
        for o in offsets {
            filterListService.remove(uuid: filters[o].id)
        }
    }
    
    func reset() {
        filterListService.reset()
    }
    
    func migrateFromV1() {
        filterListService.migrateFromV1()
    }
    
    func saveHasLaunchedApp() {        
        appSettings.numberOfLaunches = appSettings.numberOfLaunches + 1
    }
    
    func requestReview() {
        self.ratingService.requestReview()
    }
        
}


