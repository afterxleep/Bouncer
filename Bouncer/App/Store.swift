//
//  Store.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/24/20.
//

import Foundation

final class Store<State, Action, Environment>: ObservableObject {
    @Published private(set) var state: State

    private let environment: Environment
    private let reducer: Reducer<State, Action, Environment>

    init(initialState: State,
         reducer: @escaping Reducer<State, Action, Environment>,
         environment: Environment
    ) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment        
    }

    func send(_ action: Action) {
        reducer(&state, action, environment)
    }
}
