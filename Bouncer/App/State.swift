//
//  State.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/24/20.
//

import Foundation

typealias Reducer<State, Action> = (inout State, Action) -> Void
typealias AppStore = Store<AppState, AppAction>

// MARK: App State
struct AppState {
    var filter: FilterState
}

enum AppAction {
    case filter(action: FilterAction)
}

func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case let .filter(action):
        filterReducer(state: &state.filter, action: action)
    }
}

// MARK: Filter State
struct FilterState {
    var filters: [Filter]
}

enum FilterAction {
    case setFilters(filters: [Filter])
}

func filterReducer(state: inout FilterState, action: FilterAction) {
    switch action {
    case .setFilters(filters: let filters):
        state.filters = filters
    }
}
