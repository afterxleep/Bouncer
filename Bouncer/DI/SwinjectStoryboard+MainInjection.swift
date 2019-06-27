//
//  SwinjectStoryboard+MainInjection.swift
//  Bouncer
//
//  Created by Miguel D Rojas Cortés on 3/17/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Swinject
import SwinjectStoryboard

extension SwinjectStoryboard {
    
    @objc class func setup() {
        
        Container.loggingFunction = nil // Get rid of the shitty logging
        
        // MARK: Registrations
        
        defaultContainer.register(WordListPresenter.self) { resolver in
            let wordListService = resolver.resolve(WordListService.self) ?? WordListFileStorageService()
            return WordListPresenter(wordListService: wordListService)
        }
        
        defaultContainer.register(WordListAddPresenter.self) { resolver in
            let wordListService = resolver.resolve(WordListService.self) ?? WordListFileStorageService()
            return WordListAddPresenter(wordListService: wordListService)
        }
        
        defaultContainer.register(TutorialPresenter.self) { resolver in
            let userDataService = resolver.resolve(UserDataService.self) ?? UserDataDefaultsService()
            return TutorialPresenter(userDataService: userDataService)
        }
        
        defaultContainer.register(FilterService.self) { resolver in
            return resolver.resolve(FilterService.self) ?? FilterWordListService()
        }
        
        // MARK: Storyboard Inits
        
        defaultContainer.storyboardInitCompleted(WordListViewController.self) { resolver, controller in
            controller.presenter = resolver.resolve(WordListPresenter.self)
        }
        
        defaultContainer.storyboardInitCompleted(WordListAddViewController.self) { resolver, controller in
            controller.presenter = resolver.resolve(WordListAddPresenter.self)
        }
        
        defaultContainer.storyboardInitCompleted(TutorialViewController.self) { resolver, controller in
            controller.presenter = resolver.resolve(TutorialPresenter.self)
        }
        
        
    }
    
}
