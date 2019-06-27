//
//  WordListAddViewController.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit

protocol WordListAddViewControllerDelegate: class {
    func wordListAddViewControllerDidFinishAddWord()
}

final class WordListAddViewController: UIViewController, WordListAddView, Storyboarded {
    
    var presenter: WordListAddPresenter?
    var noNotificationMsgText: String?
    var enterWordText: String?
    
    var delegate: WordListAddViewControllerDelegate?
    
    //MARK: - Outlets
    
    @IBOutlet weak private var wordTxt: UITextField?
    @IBOutlet weak var formHelpTxt: UITextView!
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter?.attachView(view: self)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    func setupUI() {
        formHelpTxt.text = noNotificationMsgText
        wordTxt?.placeholder = enterWordText
        wordTxt?.becomeFirstResponder()
    }
    
    //MARK: - Actions
    
    @IBAction func addWord() {
        if let text = wordTxt?.text, !text.isEmpty {
            presenter?.addWord(word: text)
            delegate?.wordListAddViewControllerDidFinishAddWord()
        }
    }
    
    @IBAction private func cancel() {        
        delegate?.wordListAddViewControllerDidFinishAddWord()
    }
    
}
