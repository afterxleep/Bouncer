//
//  Store.swift
//  Bouncer
//
//  Created by Daniel Bernal on 7/24/20.
//

import Foundation
import Combine

final class Store<State, Action, Environment>: ObservableObject {
    @Published private(set) var state: State

    private let environment: Environment
    private let reducer: Reducer<State, Action, Environment>
    private var cancellables: Set<AnyCancellable> = []

    init(initialState: State,
         reducer: @escaping Reducer<State, Action, Environment>,
         environment: Environment
    ) {
        self.state = initialState
        self.reducer = reducer
        self.environment = environment        
    }

    func send(_ action: Action) {
        guard let effect = reducer(&state, action, environment) else { return }
        
        effect
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
}
