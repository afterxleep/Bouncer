//
//  State.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/24/20.
//

import Foundation

typealias Reducer<State, Action, Environment> = (inout State, Action, Environment) -> Void
typealias AppStore = Store<AppState, AppAction, AppEnvironment>
typealias FilterStore = Store<FilterState, FilterAction, AppEnvironment>

struct AppEnvironment {
    var filterStore: FilterStoreProtocol = FilterStoreFile()
}

// MARK: App State
struct AppState {
    var filter: FilterState = FilterState()
}

enum AppAction {
    case filter(action: FilterAction)
}

func appReducer(state: inout AppState, action: AppAction, environment: AppEnvironment) {
    switch action {
    case let .filter(action):
        filterReducer(state: &state.filter, action: action, environment: environment)
    }
}

// MARK: Filter State
struct FilterState {
    var list: [Filter] = []
}

enum FilterAction {
    case load
}

func filterReducer(state: inout FilterState, action: FilterAction, environment: AppEnvironment) {
    switch action {
    case .load:
        state.list = environment.filterStore.filters
    }
}
