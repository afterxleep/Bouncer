//
//  AnalyticsMiddlewareTests.swift
//  BouncerTests
//

import XCTest
import Combine
@testable import Bouncer

final class AnalyticsMiddlewareTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testFilterCreateAction() {
        // Create a mock analytics service
        let mockAnalyticsService = MockAnalyticsService(shouldReturnNilClient: false)
        
        // Create the middleware
        let middleware = analyticsMiddleware(analyticsService: mockAnalyticsService)
        
        // Create a mock state and filter
        let filter = Filter(name: "Test Filter", regex: "Test.*", isEnabled: true)
        let state = AppState(settings: SettingsState(), filters: FilterState())
        
        // Create the action
        let action = AppAction.filter(action: .add(filter: filter))
        
        // Expectation for async operation
        let expectation = XCTestExpectation(description: "Filter create action")
        
        // Call the middleware
        guard let publisher = middleware(state, action) else {
            XCTFail("Middleware should return a publisher")
            return
        }
        
        publisher
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: { resultAction in
                    // Check that it was transformed to a "none" action
                    if case .none = resultAction {
                        // This is correct
                    } else {
                        XCTFail("Expected .none action, got \(resultAction)")
                    }
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the event was saved
        XCTAssertTrue(mockAnalyticsService.eventSaved, "Analytics event should be saved")
    }
    
    func testFilterDeleteAction() {
        // Create a mock analytics service
        let mockAnalyticsService = MockAnalyticsService(shouldReturnNilClient: false)
        
        // Create the middleware
        let middleware = analyticsMiddleware(analyticsService: mockAnalyticsService)
        
        // Create a filter
        let filter = Filter(name: "Test Filter", regex: "Test.*", isEnabled: true)
        
        // Create the state with the filter
        var filterState = FilterState()
        filterState.filters = [filter]
        let state = AppState(settings: SettingsState(), filters: filterState)
        
        // Create the action to delete the filter
        let action = AppAction.filter(action: .delete(uuid: filter.uuid))
        
        // Expectation for async operation
        let expectation = XCTestExpectation(description: "Filter delete action")
        
        // Call the middleware
        guard let publisher = middleware(state, action) else {
            XCTFail("Middleware should return a publisher")
            return
        }
        
        publisher
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: { resultAction in
                    // Check that it was transformed to a "none" action
                    if case .none = resultAction {
                        // This is correct
                    } else {
                        XCTFail("Expected .none action, got \(resultAction)")
                    }
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the event was saved
        XCTAssertTrue(mockAnalyticsService.eventSaved, "Analytics event should be saved")
    }
    
    func testOtherActions() {
        // Create a mock analytics service
        let mockAnalyticsService = MockAnalyticsService(shouldReturnNilClient: false)
        
        // Create the middleware
        let middleware = analyticsMiddleware(analyticsService: mockAnalyticsService)
        
        // Create the state
        let state = AppState(settings: SettingsState(), filters: FilterState())
        
        // Create a different action that shouldn't trigger analytics
        let action = AppAction.settings(action: .fetchSettings)
        
        // Call the middleware
        let publisher = middleware(state, action)
        
        // Verify no publisher is returned for unhandled actions
        XCTAssertTrue(publisher?.isEmpty ?? false, "Publisher should be empty for unhandled actions")
        
        // Verify no event was saved
        XCTAssertFalse(mockAnalyticsService.eventSaved, "No analytics event should be saved")
    }
} 