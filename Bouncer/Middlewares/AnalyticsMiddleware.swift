//
//  AnalyticsMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

func analyticsMiddleware(analyticsService: AnalyticsService) -> Middleware<AppState, AppAction> {
    
    return { state, action in
        switch action {
        case .filter(action: .add(let filter)):
            return analyticsService.saveEvent(filter: filter, eventType: .filterCreated)
                .map { _ in AppAction.none }
                .catch { _ in Just(AppAction.none) }
                .eraseToAnyPublisher()
                
        case .filter(action: .delete(let uuid)):
            if let filter = state.filters.filters.first(where: { $0.id == uuid }) {
                return analyticsService.saveEvent(filter: filter, eventType: .filterDeleted)
                    .map { _ in AppAction.none }
                    .catch { _ in Just(AppAction.none) }
                    .eraseToAnyPublisher()
            }
            
        default:
            break
        }
        
        return Empty().eraseToAnyPublisher()
    }
} 
