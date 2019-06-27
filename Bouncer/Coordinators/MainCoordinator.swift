//
//  MainCoordinator.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit

class MainCoordinator: Coordinator {

    let storyBoard = "Main"
    var userDataService: UserDataService
    var childCoordinators = [Coordinator]()
    let navigationController: BaseNavController
    
    init(navigationController: BaseNavController, userDataService: UserDataService) {
        self.userDataService = userDataService
        self.navigationController = navigationController
    }
    
    func start() {
        wordList()
    }
    
    //MARK: - Navigation
    
    func wordList() {
        let vc = WordListViewController.instatiate(fromStoryboard: storyBoard)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: false)        
    }
    
    func addWord() {
        let vc = WordListAddViewController.instatiate(fromStoryboard: storyBoard)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func tutorial() {
        let vc = TutorialViewController.instatiate(fromStoryboard: storyBoard)
        vc.delegate = self
        navigationController.visibleViewController?.present(vc, animated: true, completion: nil)
    }
    
    func help() {
        let vc = TutorialViewController.instatiate(fromStoryboard: storyBoard)        
        vc.delegate = self
        navigationController.visibleViewController?.present(vc, animated: true, completion: nil)
    }
    
    
}

/* MARK: - WordListViewControllerDelegate */
    
extension MainCoordinator: WordListViewControllerDelegate {
    
    func wordListViewControllerDidTapHelpButton() {
        help()
    }
    
    
    func wordListViewControllerDidAppear() {
        if(!userDataService.hasLaunchedApp) {
                tutorial()
        }
    }
    
    func wordListViewControllerDidTapAddButton() {
        addWord()
    }
    
}
    
/* MARK: - WordListAddViewControllerDelegate */
    
extension MainCoordinator: WordListAddViewControllerDelegate {
    
    func wordListAddViewControllerDidFinishAddWord() {
        navigationController.popViewController(animated: true)
    }
}

/* MARK: - TutorialViewControllerDelegate */

extension MainCoordinator: TutorialViewControllerDelegate {
    
    func tutorialViewControllerDidPressSkipButton() {
        userDataService.hasLaunchedApp = true
        navigationController.dismiss(animated: true, completion: nil)
    }
}


