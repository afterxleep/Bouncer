//
//  FilterMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

enum FilterMiddlewareError {
    case loadError
    case addError
    case updateError
    case deleteError
    case unknown
    case decodingError
}

func filterMiddleware(filterStore: FilterStore, analyticsService: AnalyticsService) -> Middleware<AppState, AppAction> {
    var cancellables = Set<AnyCancellable>()
    
    // Debug the Supabase configuration on middleware initialization
    print("DEBUG - Analytics Middleware Initialization")
    print("DEBUG - Analytics client valid: \(analyticsService.hasValidClient)")
    print("DEBUG - Supabase URL set: \(!AppConfig.supabaseURL.isEmpty && !AppConfig.supabaseURL.contains("YOUR_"))")
    print("DEBUG - Supabase Key set: \(!AppConfig.supabaseKey.isEmpty && !AppConfig.supabaseKey.contains("YOUR_"))")
    if !analyticsService.hasValidClient {
        print("WARNING - Analytics client not initialized. Check your AppConfig values:")
        print("WARNING - Supabase URL: \(AppConfig.supabaseURL.isEmpty ? "EMPTY" : AppConfig.supabaseURL)")
        if AppConfig.supabaseURL.contains("YOUR_") {
            print("WARNING - Supabase URL contains placeholder text")
        }
        if AppConfig.supabaseKey.contains("YOUR_") {
            print("WARNING - Supabase Key contains placeholder text")
        }
    }
    
    return { state, action in
        switch action {
        
        case .filter(action: .fetch):
            return filterStore.fetch()
                .map { AppAction.filter(action: .fetchComplete(filters: $0 )) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .loadError:
                        return Just(AppAction.filter(action: .fetchError(error: FilterMiddlewareError.loadError)))
                        
                    default:
                        return Just(AppAction.filter(action: .fetchError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()
            
        case .filter(action: .add(let filter)):
            // Track analytics event for filter creation
            print("Analytics: Saving filter creation event - \(filter.phrase)")
            analyticsService.saveEvent(filter: filter, eventType: .filterCreated)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Analytics ERROR: Failed to save filter creation event")
                            print("Analytics ERROR details: \(error)")
                            
                            // Check Supabase configuration
                            print("Analytics DEBUG: Service initialized with client: \(analyticsService.hasValidClient ? "YES" : "NO")")
                            print("Analytics DEBUG: Supabase URL value: \(AppConfig.supabaseURL)")
                            print("Analytics DEBUG: Supabase Key valid: \(!AppConfig.supabaseKey.isEmpty && !AppConfig.supabaseKey.contains("YOUR_") ? "YES" : "NO")")
                        }
                    },
                    receiveValue: { _ in
                        print("Analytics: Successfully saved filter creation event")
                    }
                )
                .store(in: &cancellables)
            
            return filterStore.add(filter: filter)
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .addError:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.addError)))
                    default:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()

        case .filter(action: .addMany(let filters)):
            return filterStore.addMany(filters: filters)
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .addError:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.addError)))
                    default:
                        return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()
            
        case .filter(action: .update(filter: let filter)):
            // Track analytics event for filter update
            print("Analytics: Saving filter update event - \(filter.phrase)")
            analyticsService.saveEvent(filter: filter, eventType: .filterUpdated)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Analytics ERROR: Failed to save filter update event")
                            print("Analytics ERROR details: \(error)")
                            
                            // Check Supabase configuration
                            print("Analytics DEBUG: Service initialized with client: \(analyticsService.hasValidClient ? "YES" : "NO")")
                            print("Analytics DEBUG: Supabase URL value: \(AppConfig.supabaseURL)")
                            print("Analytics DEBUG: Supabase Key valid: \(!AppConfig.supabaseKey.isEmpty && !AppConfig.supabaseKey.contains("YOUR_") ? "YES" : "NO")")
                        }
                    },
                    receiveValue: { _ in
                        print("Analytics: Successfully saved filter update event")
                    }
                )
                .store(in: &cancellables)
            
            return filterStore.update(filter: filter)
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch error {
                    case .updateError:
                        return Just(AppAction.filter(action: .updateError(error: .updateError)))
                    default:
                        return Just(AppAction.filter(action: .updateError(error: .unknown)))
                    }
                }
                .eraseToAnyPublisher()
            
        case .filter(action: .delete(let uuid)):
            // Track analytics event for filter deletion
            if let filter = state.filters.filters.first(where: { $0.id == uuid }) {
                print("Analytics: Saving filter deletion event - \(filter.phrase)")
                analyticsService.saveEvent(filter: filter, eventType: .filterDeleted)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("Analytics ERROR: Failed to save filter deletion event")
                                print("Analytics ERROR details: \(error)")
                                
                                // Check Supabase configuration
                                print("Analytics DEBUG: Service initialized with client: \(analyticsService.hasValidClient ? "YES" : "NO")")
                                print("Analytics DEBUG: Supabase URL value: \(AppConfig.supabaseURL)")
                                print("Analytics DEBUG: Supabase Key valid: \(!AppConfig.supabaseKey.isEmpty && !AppConfig.supabaseKey.contains("YOUR_") ? "YES" : "NO")")
                            }
                        },
                        receiveValue: { _ in
                            print("Analytics: Successfully saved filter deletion event")
                        }
                    )
                    .store(in: &cancellables)
            }
            
            return filterStore.remove(uuid: uuid)                    
                .map { AppAction.filter(action: .fetch) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    case .addError:
                        return Just(AppAction.filter(action: .deleteError(error: FilterMiddlewareError.deleteError)))
                        
                    default:
                        return Just(AppAction.filter(action: .deleteError(error: FilterMiddlewareError.unknown)))
                    }
                }
                .eraseToAnyPublisher()

        case .filter(action: .loadFromURL(url: let url)):
            return filterStore.decodeFromURL(url: url)
                .map { AppAction.filter(action: .decodeComplete(filters: $0 )) }
                .catch { (error: FilterStoreError) -> Just<AppAction> in
                    switch(error) {
                    default:
                        return Just(AppAction.filter(action: .error(.decodingError("INCORRECT_FILE_FORMAT"))))
                    }
                }
                .eraseToAnyPublisher()

        default:
            break
        }
        return Empty().eraseToAnyPublisher()


    }
    
}
