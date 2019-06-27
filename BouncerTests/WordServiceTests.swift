//
//  WordListServiceTests.swift
//  BouncerTests
//
//  Created by Daniel Bernal on 4/13/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import XCTest
import Swinject
@testable import Bouncer

class WordListServiceTests: XCTestCase {
    
    private let container = Container()
    
    override func setUp() {}
    
    override func tearDown() {}
    
    func testWordListFileStorageService() {
        container.register(WordListService.self) { resolver in
            return WordListFileStorageService()
        }
        let service = container.resolve(WordListService.self)
        let testWords = ["raPpi", "ráppI", "créDito", "comprar", "tílde", "tilde", "comprar", "ábaco", "123"]
        let validationWords = ["123", "abaco", "comprar", "credito", "rappi", "tilde"]
        service?.save(wordList: testWords)
        let readWords = service?.read()
        XCTAssert(readWords == validationWords)
    }
    
}

