//
//  AppReducer.swift
//  Bouncer
//

import Foundation

typealias Reducer<State, Action> = (inout State, Action) -> Void

func appReducer(state: inout AppState, action: AppAction) -> Void {
    switch(action) {

    case .filter(let action):
        filterReducer(state: &state.filters, action: action)

    case .settings(let action):
        settingsReducer(state: &state.settings, action: action)
        
    }
}
