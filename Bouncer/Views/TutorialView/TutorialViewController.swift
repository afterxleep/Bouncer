//
//  TutorialViewController.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit

protocol TutorialViewControllerDelegate: class {
    func tutorialViewControllerDidPressSkipButton()
}

final class TutorialViewController: UIViewController, TutorialView, Storyboarded {
    
    var presenter: TutorialPresenter?
    var delegate: TutorialViewControllerDelegate?
    
    var introText: String?
    var buttonText: String?
    var settingsText: String?
    var msgsText: String?
    var spamText: String?
    var bouncerText: String?
    
    //MARK: - Outlets
    
    @IBOutlet weak private var navigationBar: UINavigationBar!
    @IBOutlet weak private var introTxtView: UITextView!
    @IBOutlet weak private var didItBtn: UIButton!
    @IBOutlet weak private var settingsLbl: UILabel!
    @IBOutlet weak private var msgsLbl: UILabel!
    @IBOutlet weak private var spamLbl: UILabel!
    @IBOutlet weak private var bouncerLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter?.attachView(view: self)
        
        titleLbl.text = title        
        introTxtView.text = introText
        didItBtn.setTitle(buttonText, for: .normal)
        settingsLbl.text = settingsText
        msgsLbl.text = msgsText
        spamLbl.text = spamText
        bouncerLbl.text = bouncerText
    }
    
    //MARK: - Actions
    
    @IBAction private func complete(_ sender: Any) {
        presenter?.DidPressSkipButton()
        self.delegate?.tutorialViewControllerDidPressSkipButton()
        
    }

}
