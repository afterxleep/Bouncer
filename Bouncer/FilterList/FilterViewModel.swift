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
    let filterListService: FilterStoreProtocol
    var userSettingsService: UserSettingsProtocol
    var ratingService: ReviewServiceProtocol
    var filterListcancellable: AnyCancellable?
    var defaultsCancellable: AnyCancellable?
    
    @Published var filters: [Filter] = []
    @Published var hasAddedFilters: Bool = true
    @Published var isFirstLaunch: Bool = false
    
    //MARK: - Initializer
    init(
        filterListService: FilterStoreProtocol = FilterStoreFile(),
        userSettingsService: UserSettingsProtocol = UserSettingsDefaults(),
        ratingService: ReviewServiceProtocol = ReviewServiceStoreKit()) {
        
        self.filterListService = filterListService
        self.userSettingsService = userSettingsService
        self.ratingService = ratingService
        
        filterListcancellable = filterListService
            .filtersPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] filters in
                    self?.filters = filters
                }
        
        migrateFromV1()
        saveHasLaunchedApp()
        requestReview()
    }
        
    func add(type: FilterType, phrase: String, action: FilterAction) {
        filterListService.add(filter: Filter(id: UUID(), phrase: phrase, type: type, action: action))
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
    
    func saveHasLaunchedApp() {        
        userSettingsService.numberOfLaunches = userSettingsService.numberOfLaunches + 1
    }
    
    func requestReview() {
        self.ratingService.requestReview()
    }
    
    func getFilterTypeDecoration(filter: Filter) -> SystemImage {
        var data: SystemImage
        switch(filter.type) {
            case .sender:
                data = FilterType.sender.listDescription
            case .message:
                data = FilterType.message.listDescription
            default:
                data = FilterType.any.listDescription
        }
        return data
    }
    
    func getFilterActionDecoration(filter: Filter) -> FilterActionDecoration {
        var data: FilterActionDecoration
        switch (filter.action) {
            case .junk:
                data = FilterAction.junk.listDescription
            case .promotion:
                data = FilterAction.promotion.listDescription
            case .transaction:
                data = FilterAction.transaction.listDescription
            }
        return data
    }
    
    var shouldDisplayList: Bool {
        if(filters.count > 0) {
            return true
        }
        return false
    }
    
    var shouldDisplayInApp: Bool {
        if(filters.count > 9) {
            return true
        }
        return true
    }
        
}


