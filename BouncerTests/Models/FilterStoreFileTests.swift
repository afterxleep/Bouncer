//
//  FilterStoreFileTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer
import Combine

class FilterStoreFileTests: XCTestCase {

    var filterStore = FilterStoreFile()

    var filters: [Filter] = [
        Filter(id: UUID(), phrase: "rappi", type: .any, action: .junk),
        Filter(id: UUID(), phrase: "etb", type: .sender, action: .promotion),
        Filter(id: UUID(), phrase: "your code", type: .message, action: .transaction),
        Filter(id: UUID(), phrase: "[b-chm-pP]at|ot", type: .message, action: .junk, useRegex: true),
        Filter(id: UUID(), phrase: "YoUR COdE", type: .message, action: .junk, useRegex: false)
    ]
    var totalOldStoreFilters = 5

    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "Reset Filters")
        _ = filterStore.reset()
            .sink(receiveCompletion: { _ in}, receiveValue: { value in
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)

        for filter in filters {
            let expectation = self.expectation(description: "Adding Test Filters")
            _ = filterStore.add(filter: filter)
                .sink(receiveCompletion: { _ in}, receiveValue: { value in
                    expectation.fulfill()
                })
            waitForExpectations(timeout: 1, handler: nil)
        }
    }
    
    override func tearDown() {
        _ = filterStore.reset()
    }

    func test10_AddFilters() {

        let expectation = self.expectation(description: "Fetch Filters")
        var filters: [Filter] = []
        _ = filterStore.fetch()
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                filters = value
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(self.filters.count, filters.count)
        
        let regexFilter = filters[0]
        XCTAssertEqual(regexFilter.phrase, "[b-chm-pP]at|ot")
        
        let wordFilter = filters[4]
        XCTAssertEqual(wordFilter.phrase, "your code")

    }

    func test20_DeleteFilter() {
        var expectation = self.expectation(description: "Fetch Filters")

        var filters: [Filter] = []
        _ = filterStore.fetch()
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                filters = value
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
        let index = Int.random(in: 0..<filters.count)
        let id = filters[index].id

        expectation = self.expectation(description: "Delete Filter")
        _ = filterStore.remove(uuid: id)
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)

        expectation = self.expectation(description: "Fetch Filters")
        _ = filterStore.fetch()
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                filters = value
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(self.filters.count-1, filters.count)

    }
}
