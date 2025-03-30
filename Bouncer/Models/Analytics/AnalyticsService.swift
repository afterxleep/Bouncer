//
//  AnalyticsService.swift
//  Bouncer
//

import Foundation
import Combine
import Supabase

enum AnalyticsServiceError: Error, CustomStringConvertible {
    case saveError
    case saveErrorWithDetails(Error)
    case unknown
    case configNotAvailable
    case encodingError
    
    var description: String {
        switch self {
        case .saveError:
            return "Failed to save analytics data"
        case .saveErrorWithDetails(let error):
            return "Failed to save analytics data: \(error.localizedDescription)"
        case .unknown:
            return "Unknown analytics error"
        case .configNotAvailable:
            return "Analytics configuration not available"
        case .encodingError:
            return "Failed to encode analytics data"
        }
    }
}

enum AnalyticsEventType: String, Codable {
    case filterCreated
    case filterDeleted
    case filterUpdated
}

struct FilterAnalyticsEvent: Codable {
    let filter: Filter
    let eventType: AnalyticsEventType
    let userLocale: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case filter
        case eventType = "eventType"
        case userLocale = "userLocale"
        case createdAt = "createdAt"
    }
}

protocol AnalyticsService {
    func saveEvent(filter: Filter, eventType: AnalyticsEventType) -> AnyPublisher<Void, AnalyticsServiceError>
    var hasValidClient: Bool { get }
}

class DefaultAnalyticsService: AnalyticsService {
    
    private let client: SupabaseClient?
    
    var hasValidClient: Bool {
        return client != nil
    }

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
            print("Analytics: No Supabase client available - check configuration")
            return Just(())
                .setFailureType(to: AnalyticsServiceError.self)
                .eraseToAnyPublisher()
        }
        
        // Get current locale and sanitize it
        let rawLocale = Locale.current.identifier
        
        // Clean up locale string to just get the basic language_region part
        // This handles complex locale identifiers like "en_US@rg=eszzzz"
        let cleanLocale: String
        if let mainPart = rawLocale.split(separator: "@").first {
            cleanLocale = String(mainPart)
        } else {
            // Fallback to a basic format if we can't parse it
            let languageCode = Locale.current.language.languageCode?.identifier ?? "unknown"
            let regionCode = Locale.current.region?.identifier ?? ""
            cleanLocale = regionCode.isEmpty ? languageCode : "\(languageCode)_\(regionCode)"
        }
        
        print("Analytics: Using sanitized locale: \(cleanLocale) (from raw: \(rawLocale))")
        
        // Format current date as ISO 8601 string for PostgreSQL compatibility
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampString = dateFormatter.string(from: Date())
        print("Analytics: Using formatted timestamp: \(timestampString)")
        
        // Create a sanitized analytics event
        let event = FilterAnalyticsEvent(
            filter: filter,
            eventType: eventType,
            userLocale: cleanLocale,
            createdAt: timestampString
        )
        
        // Debug the data being sent
        print("Analytics: Sending event data:")
        print("Analytics: - Event type: \(eventType.rawValue)")
        print("Analytics: - Filter ID: \(filter.id)")
        print("Analytics: - Filter phrase: \(filter.phrase)")
        
        // Function to attempt the database operation with a retry mechanism
        func attemptSaveWithRetry(retryCount: Int = 3, currentAttempt: Int = 1) -> Future<Void, AnalyticsServiceError> {
            return Future { promise in
                Task {
                    do {
                        print("Analytics: Inserting into table: \(Constants.filterAnalyticsTable) (attempt \(currentAttempt)/\(retryCount))")
                        
                        // Store the event in the "filter_analytics" table
                        _ = try await client.database
                            .from(Constants.filterAnalyticsTable)
                            .insert(event)
                            .execute()
                        
                        print("Analytics: Successfully saved event")
                        promise(.success(()))
                    } catch let error {
                        // Check if this is a network error that could benefit from a retry
                        let isNetworkError = self.isNetworkRelatedError(error)
                        
                        print("Analytics ERROR: Failed to save data (attempt \(currentAttempt)/\(retryCount))")
                        print("Analytics ERROR: \(error)")
                        
                        if let postgrestError = error as? PostgrestError {
                            print("Analytics ERROR details:")
                            print("- Detail: \(postgrestError.detail ?? "nil")")
                            print("- Code: \(postgrestError.code ?? "nil")")
                            print("- Message: \(postgrestError.message ?? "nil")")
                            
                            // Check if it's a table not found error
                            let errorMessage = postgrestError.message ?? ""
                            if errorMessage.contains("relation") && errorMessage.contains("does not exist") {
                                print("Analytics: Table may not exist. Please check Supabase schema.")
                            }
                        }
                        
                        // If we have retries left and it's a network error, try again
                        if currentAttempt < retryCount && isNetworkError {
                            print("Analytics: Network error detected. Retrying in 1 second...")
                            
                            // Wait 1 second before retrying
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            
                            // Try again
                            let retryFuture = attemptSaveWithRetry(retryCount: retryCount, currentAttempt: currentAttempt + 1)
                            retryFuture.sink(
                                receiveCompletion: { completion in
                                    if case .failure(let retryError) = completion {
                                        promise(.failure(retryError))
                                    }
                                },
                                receiveValue: { value in
                                    promise(.success(value))
                                }
                            ).cancel()
                        } else {
                            if isNetworkError {
                                print("Analytics: Exhausted retry attempts. Network error persists.")
                            }
                            promise(.failure(.saveErrorWithDetails(error)))
                        }
                    }
                }
            }
        }
        
        return attemptSaveWithRetry().eraseToAnyPublisher()
    }

    // Helper method to determine if an error is network-related
    private func isNetworkRelatedError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        // Check for common network error domains and codes
        if nsError.domain == NSURLErrorDomain {
            // Common network error codes
            let networkErrorCodes = [
                NSURLErrorTimedOut,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet,
                NSURLErrorInternationalRoamingOff,
                NSURLErrorCallIsActive,
                NSURLErrorDataNotAllowed,
                NSURLErrorCannotFindHost,
                NSURLErrorDNSLookupFailed
            ]
            
            return networkErrorCodes.contains(nsError.code)
        }
        
        // Check for CFNetwork errors
        if nsError.domain == "kCFErrorDomainCFNetwork" || nsError.domain == "NSPOSIXErrorDomain" {
            return true
        }
        
        // Check for specific error message patterns
        let errorString = error.localizedDescription.lowercased()
        let networkErrorKeywords = ["network", "internet", "connection", "offline", "timeout", "timed out", "unreachable", "host", "DNS"]
        
        return networkErrorKeywords.contains { errorString.contains($0) }
    }
}