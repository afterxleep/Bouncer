//
//  AnalyticsServiceTests.swift
//  BouncerTests
//

import XCTest
import Combine
@testable import Bouncer

final class AnalyticsServiceTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testSaveEventWithoutClient() {
        // Setup a mock analytics service without valid Supabase client
        let mockAnalyticsService = MockAnalyticsService(shouldReturnNilClient: true)
        
        // Create test filter
        let filter = Filter(name: "Test Filter", regex: "Test.*", isEnabled: true)
        
        // Expectation for async operation
        let expectation = XCTestExpectation(description: "Save event without client")
        
        // Test that it completes without error
        mockAnalyticsService.saveEvent(filter: filter, eventType: .filterCreated)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail when client is nil")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSaveEventWithClient() {
        // Setup a mock analytics service with mock client
        let mockAnalyticsService = MockAnalyticsService(shouldReturnNilClient: false)
        
        // Create test filter
        let filter = Filter(name: "Test Filter", regex: "Test.*", isEnabled: true)
        
        // Expectation for async operation
        let expectation = XCTestExpectation(description: "Save event with client")
        
        // Test successful event saving
        mockAnalyticsService.saveEvent(filter: filter, eventType: .filterCreated)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail with mock client")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTAssertTrue(mockAnalyticsService.eventSaved, "Event should be saved")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSaveEventWithEncodingError() {
        // Setup a mock analytics service that will simulate encoding errors
        let mockAnalyticsService = MockAnalyticsService(shouldReturnNilClient: false, shouldFailEncoding: true)
        
        // Create test filter
        let filter = Filter(name: "Test Filter", regex: "Test.*", isEnabled: true)
        
        // Expectation for async operation
        let expectation = XCTestExpectation(description: "Save event with encoding error")
        
        // Test encoding error handling
        mockAnalyticsService.saveEvent(filter: filter, eventType: .filterCreated)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertEqual(error, .encodingError, "Should fail with encoding error")
                    } else {
                        XCTFail("Should fail with encoding error")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value on encoding error")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Analytics Service
class MockAnalyticsService: AnalyticsService {
    private let shouldReturnNilClient: Bool
    private let shouldFailEncoding: Bool
    var eventSaved = false
    
    init(shouldReturnNilClient: Bool, shouldFailEncoding: Bool = false) {
        self.shouldReturnNilClient = shouldReturnNilClient
        self.shouldFailEncoding = shouldFailEncoding
    }
    
    func saveEvent(filter: Filter, eventType: AnalyticsEventType) -> AnyPublisher<Void, AnalyticsServiceError> {
        if shouldReturnNilClient {
            return Just(())
                .setFailureType(to: AnalyticsServiceError.self)
                .eraseToAnyPublisher()
        }
        
        if shouldFailEncoding {
            return Fail(error: AnalyticsServiceError.encodingError)
                .eraseToAnyPublisher()
        }
        
        eventSaved = true
        return Just(())
            .setFailureType(to: AnalyticsServiceError.self)
            .eraseToAnyPublisher()
    }
} 