//
//  TutorialPresenter.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation
import UIKit

final class TutorialPresenter: BasePresenter {
    
    typealias View = TutorialView
    
    private var tutorialView : TutorialView?
    var userDataService: UserDataService
    
    enum strings: String {
        case welcome
        case enableSMSFiltering
        case help
        case enableSMSFilteringHelp
        case didIt
        case ok
        case goToSettings
        case tapMessages
        case tapSpam
        case toggleBouncer
    }
    
    init(userDataService: UserDataService) {
        self.userDataService = userDataService
    }
    
    //MARK: - BasePresenter
    
    func attachView(view: TutorialView) {
        tutorialView = view
        
        tutorialView?.title = strings.help.rawValue.localized
        tutorialView?.introText = strings.enableSMSFilteringHelp.rawValue.localized
        tutorialView?.buttonText = strings.ok.rawValue.localized
        tutorialView?.settingsText = strings.goToSettings.rawValue.localized
        tutorialView?.msgsText = strings.tapMessages.rawValue.localized
        tutorialView?.spamText = strings.tapSpam.rawValue.localized
        tutorialView?.bouncerText = strings.toggleBouncer.rawValue.localized
        
        if(!userDataService.hasLaunchedApp) {
            tutorialView?.title = strings.welcome.rawValue.localized
            tutorialView?.introText = strings.enableSMSFiltering.rawValue.localized
            tutorialView?.buttonText = strings.didIt.rawValue.localized
        }
        
        
    }
    
    func detachView() {
        tutorialView = nil
    }
    
    func destroy() {
        
    }
    
    func DidPressSkipButton() {
        if(!userDataService.hasLaunchedApp) {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:])
            }
        }
        
    }
    
}
