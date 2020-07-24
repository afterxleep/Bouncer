//
//  State.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/24/20.
//

import Foundation
import Combine

typealias Reducer<State, Action, Environment> = (inout State, Action, Environment) -> AnyPublisher<Action, Never>?
typealias AppStore = Store<AppState, AppAction, AppEnvironment>
typealias FilterStore = Store<FilterState, FilterAction, AppEnvironment>

struct AppEnvironment {
    var filterStore: FilterStoreProtocol = FilterStoreFile()
}

// MARK: App State
struct AppState {
    var filterState: FilterState = FilterState()
}

enum AppAction {
    case filter(action: FilterAction)
}

func appReducer(state: inout AppState, action: AppAction, environment: AppEnvironment) -> AnyPublisher<AppAction, Never>? {
    switch action {
    case let .filter(action):
        return filterReducer(state: &state.filterState, action: action, environment: environment)
    }
}

// MARK: Filter State
struct FilterState {
    var filters: [Filter] = []
}

enum FilterAction {
    case setFilters(filters: [Filter])
    case load
    case remove(uuid: UUID)
}

func filterReducer(state: inout FilterState, action: FilterAction, environment: AppEnvironment) -> AnyPublisher<AppAction, Never>? {
    switch action {
    
    case let .setFilters(filters):
        state.filters = filters
    
    case .load:
        return environment.filterStore.get()
            .replaceError(with: [])
            .map { AppAction.filter(action: .setFilters(filters: $0))}
            .eraseToAnyPublisher()
        
    case .remove(let uuid):
        return environment.filterStore.remove(id: uuid)
            .map { _ in AppAction.filter(action: .load)}            
            .eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}
