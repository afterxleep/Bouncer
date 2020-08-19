//
//  FilterStoreFileTests.swift
//  BouncerTests
//

import XCTest
@testable import Bouncer
import Combine

class FilterStoreFileTests: XCTestCase {

    var filterStore = FilterStoreFile()
    var fileManager = FileManager.default
    var filters: [Filter] = [
        Filter(id: UUID(), phrase: "rappi", type: .any, action: .junk),
        Filter(id: UUID(), phrase: "etb", type: .sender, action: .promotion),
        Filter(id: UUID(), phrase: "your code", type: .message, action: .transaction)
    ]

    fileprivate var filterURL: URL {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: FilterStoreFile.groupContainer)!
            .appendingPathComponent(FilterStoreFile.filterListFile)
    }

    fileprivate var V1Url: URL {
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: FilterStoreFile.groupContainer)!
            .appendingPathComponent(FilterStoreFile.filterListFileV1)
    }

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


    func test01_AddFilters() {

        let expectation = self.expectation(description: "Fetch Filters")
        var filters: [Filter] = []
        _ = filterStore.fetch()
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                filters = value
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(self.filters.count, filters.count)


    }

    func test02_DeleteFilter() {
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
