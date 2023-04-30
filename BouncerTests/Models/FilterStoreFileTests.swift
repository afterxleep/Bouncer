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
        Filter(id: UUID(), phrase: "etb", type: .sender, action: .promotion, subAction: .none, useRegex: false),
        Filter(id: UUID(), phrase: "etb2", type: .sender, action: .promotion, subAction: .promotionCoupons, useRegex: false),
        Filter(id: UUID(), phrase: "etb3", type: .sender, action: .promotion, subAction: .promotionOffers, useRegex: false),
        Filter(id: UUID(), phrase: "your code", type: .message, action: .transaction, subAction: .none, useRegex: false),
        Filter(id: UUID(), phrase: "your code2", type: .message, action: .transaction, subAction: .transactionOrder, useRegex: false),
        Filter(id: UUID(), phrase: "your code3", type: .message, action: .transaction, subAction: .transactionFinance, useRegex: false),
        Filter(id: UUID(), phrase: "your code4", type: .message, action: .transaction, subAction: .transactionReminders, useRegex: false),
        Filter(id: UUID(), phrase: "[b-chm-pP]at|ot", type: .message, action: .junk, subAction: .none, useRegex: true),
        Filter(id: UUID(), phrase: "YoUR COdE", type: .message, action: .junk, subAction: .none, useRegex: true)
    ]
    var totalOldStoreFilters = 5

    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "Reset Filters")
        _ = filterStore.reset()
            .sink(receiveCompletion: { _ in }, receiveValue: { value in
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)

        for filter in filters {
            let expectation = self.expectation(description: "Adding Test Filters")
            _ = filterStore.add(filter: filter)
                .sink(receiveCompletion: { _ in }, receiveValue: { value in
                    expectation.fulfill()
                })
            waitForExpectations(timeout: 1, handler: nil)
        }
    }
    
    override func tearDown() {
        _ = filterStore.reset()
    }

    func test10_AddFilters() {
        let filters: [Filter] = self.fetchFilters()
        XCTAssertEqual(self.filters.count, filters.count)

        let regexFilter = filters[1]
        XCTAssertEqual(regexFilter.phrase, "[b-chm-pP]at|ot")
        
        let wordFilter = filters[6]
        XCTAssertEqual(wordFilter.phrase, "your code")

    }
    
    func test15_AddManyFilters() {
        var filters: [Filter] = self.fetchFilters()
        XCTAssertEqual(self.filters.count, filters.count)
        
        let newFilter = Filter(id: UUID(), phrase: "some new filter")
        let newFilters = [
            filters.first(where: { $0.phrase == "rappi" })!,
            newFilter,
        ]
        
        let expectation = self.expectation(description: "Add Many Filters")
        _ = filterStore.addMany(filters: newFilters)
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
        
        filters = self.fetchFilters()
        XCTAssertEqual(self.filters.count + newFilters.count, filters.count)
        
        let rappis = filters.filter { $0.phrase == "rappi" }
        XCTAssertEqual(2, rappis.count)
        XCTAssertEqual(2, Set(rappis.map(\.id)).count, "Expected duplicate filters to have different IDs")
        
        let addedNewFilters = filters.filter { $0.phrase == newFilter.phrase }
        XCTAssertEqual(1, addedNewFilters.count)
        XCTAssertEqual(newFilter.id, addedNewFilters.first!.id)
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

    func test99_MigrateV1() {
        let oldStoreData = [
            FilterV1(id: UUID(), phrase: "rappi", type: .any, action: .junk),
            FilterV1(id: UUID(), phrase: "etb", type: .sender, action: .promotion),
            FilterV1(id: UUID(), phrase: "your code", type: .message, action: .transaction),
            FilterV1(id: UUID(), phrase: "[b-chm-pP]at|ot", type: .message, action: .junk, useRegex: true),
            FilterV1(id: UUID(), phrase: "YoUR COdE", type: .message, action: .junk, useRegex: false)
        ]
        guard let data = try? JSONEncoder().encode(oldStoreData),
              let url = FilterStoreFile.fileURL else {
            XCTFail("Could not encode legacy data")
            return
        }
        do {
            try data.write(to: url)
        } catch {
            XCTFail("Could not write sample data")
            return
        }

        let migrator = FilterStoreFileMigrator(store: self.filterStore)
        let expectation = self.expectation(description: "Fetch Filters")
        _ = migrator.migrateV1()
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                expectation.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
        let filters: [Filter] = self.fetchFilters()
        XCTAssertEqual(filters.count, 5)

        var filter = filters[0]
        XCTAssertEqual(filter.phrase, "YoUR COdE")
        XCTAssertEqual(filter.action, .junk)
        XCTAssertEqual(filter.subAction, .none)
        XCTAssertEqual(filter.useRegex, false)

        filter = filters[1]
        XCTAssertEqual(filter.phrase, "[b-chm-pP]at|ot")
        XCTAssertEqual(filter.action, .junk)
        XCTAssertEqual(filter.subAction, .none)
        XCTAssertEqual(filter.useRegex, false)

        filter = filters[2]
        XCTAssertEqual(filter.phrase, "etb")
        XCTAssertEqual(filter.action, .promotion)
        XCTAssertEqual(filter.subAction, .promotionOther)
        XCTAssertEqual(filter.useRegex, false)

        filter = filters[3]
        
        //XCTAssertEqual(filter.phrase, "[b-chm-pP]at|ot")
        //XCTAssertEqual(filter.action, .junk)
        //XCTAssertEqual(filter.subAction, .none)
        //XCTAssertEqual(filter.useRegex, true)

        filter = filters[4]
        //XCTAssertEqual(filter.phrase, "YoUR COdE")
        //XCTAssertEqual(filter.action, .junk)
        //XCTAssertEqual(filter.subAction, .none)
        //XCTAssertEqual(filter.useRegex, false)

    }
    
    private func fetchFilters() -> [Filter] {
        let expectation = self.expectation(description: "Fetch Filters")
        var filters: [Filter] = []
        _ = filterStore.fetch()
            .sink(receiveCompletion: {_ in }, receiveValue: { value in
                filters = value
                expectation.fulfill()
            })
        waitForExpectations(timeout: 1, handler: nil)
        return filters
    }
}
