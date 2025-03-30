//
//  AnalyticsService.swift
//  Bouncer
//

import Foundation
import Combine
import Supabase

enum AnalyticsServiceError: Error {
    case saveError
    case unknown
    case configNotAvailable
    case encodingError
}

enum AnalyticsEventType: String, Codable {
    case filterCreated
    case filterDeleted
}

struct FilterAnalyticsEvent: Codable {
    let filter: Filter
    let eventType: AnalyticsEventType
    let userLocale: String
    let createdAt: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case filter
        case eventType = "eventType"
        case userLocale = "userLocale"
        case createdAt = "createdAt"
    }
}

protocol AnalyticsService {
    func saveEvent(filter: Filter, eventType: AnalyticsEventType) -> AnyPublisher<Void, AnalyticsServiceError>
}

class DefaultAnalyticsService: AnalyticsService {
    
    private let client: SupabaseClient?

    struct Constants {
        static let filterAnalyticsTable = "filter_analytics"
    }
    
    init() {
        if let url = URL(string: AppConfig.supabaseURL),
           !AppConfig.supabaseKey.contains("YOUR_") && !AppConfig.supabaseKey.isEmpty {
            client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: AppConfig.supabaseKey
            )
        } else {
            client = nil
        }
    }
    
    func saveEvent(filter: Filter, eventType: AnalyticsEventType = .filterCreated) -> AnyPublisher<Void, AnalyticsServiceError> {
        // If no client is available, return early without error
        guard let client = client else {
            return Just(())
                .setFailureType(to: AnalyticsServiceError.self)
                .eraseToAnyPublisher()
        }
        
        // Get current locale
        let locale = Locale.current.identifier
        
        // Create analytics event object with the full filter
        let event = FilterAnalyticsEvent(
            filter: filter,
            eventType: eventType,
            userLocale: locale,
            createdAt: Date().timeIntervalSince1970
        )
        
        return Future { promise in
            Task {
                do {
                    // Store the event in the "filter_analytics" table
                    _ = try await client.database
                        .from(Constants.filterAnalyticsTable)
                        .insert(event)
                        .execute()
                    
                    promise(.success(()))
                } catch {
                    promise(.failure(.saveError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}