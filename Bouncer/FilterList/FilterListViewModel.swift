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
    var cancellable: AnyCancellable?
    
    @Published var filters: [Filter] = []
    
    //MARK: - Initializer
    init() {
        cancellable = filterListService
            .$filters
                .receive(on: RunLoop.main)
                .sink { [weak self] filters in
                    self?.filters = filters
                }
    }
    
    func add(type: FilterType, phrase: String, exactMatch: Bool) {
        filterListService.add(filter: Filter(id: UUID(), type: type, phrase: phrase, exactMatch: exactMatch))
    }
    
    func remove(at offsets: IndexSet) {
        for o in offsets {
            filterListService.remove(id: filters[o].id)
        }
    }
    
    func reset() {
        filterListService.reset()
    }
        
}


