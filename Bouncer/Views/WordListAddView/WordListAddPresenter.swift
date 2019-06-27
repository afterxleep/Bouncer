//
//  WordListAddPresenter.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class WordListAddPresenter: BasePresenter {

    typealias View = WordListAddView
    
    enum strings: String {
        case addWord
        case noNotificationMsg
        case enterWord
    }
    
    private var wordListAddView : WordListAddView?
    let wordListService: WordListService?
    
    //MARK: - Initializer
    
    init(wordListService: WordListService) {
        self.wordListService = wordListService
    }
    
    //MARK: - BasePresenter
    
    func attachView(view: WordListAddView) {
        wordListAddView = view
        wordListAddView?.title = strings.addWord.rawValue.localized
        wordListAddView?.noNotificationMsgText = strings.noNotificationMsg.rawValue.localized
        wordListAddView?.enterWordText = strings.enterWord.rawValue.localized
    }
    
    func detachView() {
        wordListAddView = nil
    }
    
    func destroy() {}
    
    //MARK: - WordListAddView
    
    func addWord(word: String) {
        if var wordlist = wordListService?.read() {
            wordlist.append(word)
            wordListService?.save(wordList: wordlist)
        }
    }
    
}
