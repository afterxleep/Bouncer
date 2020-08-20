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
        Filter(id: UUID(), phrase: "your code", type: .message, action: .transaction)
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

    func test00_migrateFromV1() {
        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(FilterStoreFile.filterListFileV1)
        let storePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FilterStoreFile.groupContainer)
        let destURL = storePath!.appendingPathComponent(FilterStoreFile.filterListFileV1)
        try? FileManager.default.copyItem(at: sourceURL, to: destURL)
        filterStore.migrateFromV1()
        sleep(2)  // Migrate is async and has no callbacks

        let expectation = self.expectation(description: "Fetch Filters")
        var filters: [Filter] = []
        _ = filterStore.fetch()
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                filters = value
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(self.filters.count + totalOldStoreFilters, filters.count)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destURL.path))

    }

    func test01_migrateFromV1NoOldData() {
        filterStore.migrateFromV1()
        let storePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FilterStoreFile.groupContainer)
        let destURL = storePath!.appendingPathComponent(FilterStoreFile.filterListFileV1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destURL.path))
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
