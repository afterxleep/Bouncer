//
//  UserDataServiceTests.swift
//  BouncerTests
//
//  Created by Daniel Bernal on 4/13/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//
import XCTest
import Swinject
@testable import Bouncer

class UserDataServiceTests: XCTestCase {
    
    private let container = Container()
    
    override func setUp() {}
    
    override func tearDown() {}
    
    func testUserDataDefaultsService() {
        
        container.register(UserDataService.self) { resolver in
            return UserDataDefaultsService()
        }
        
        var defaultsService = container.resolve(UserDataService.self)
        
        // hasLaunchedApp
        defaultsService?.hasLaunchedApp = false
        XCTAssertFalse(defaultsService!.hasLaunchedApp)
        defaultsService?.hasLaunchedApp = true
        XCTAssertTrue(defaultsService!.hasLaunchedApp)
        
    }
    
}
