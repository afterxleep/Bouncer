//
//  WordListPresenter.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class WordListPresenter: BasePresenter {
    
    typealias View = WordListView
        
    enum strings: String {
        case blockList
        case remove
    }
    
    //MARK: - Stored Properties
    
    let wordListService: WordListService
    var wordList = [String]()
        
    private var wordListView : WordListView?
    
    //MARK: - Initializer
    
    init(wordListService: WordListService) {
        self.wordListService = wordListService
    }
    
    func attachView(view: WordListView) {
        wordListView = view
        wordListView?.title = strings.blockList.rawValue.localized
        wordListView?.removeButtonText = strings.remove.rawValue.localized
        wordListView?.removeButtonBgColor = .red
    }
    
    func detachView() {
        wordListView = nil
    }
    
    func destroy() {
        
    }
    
    func saveWordList() {
        wordListService.save(wordList: wordList)
    }
    
    func readWordList() {
        wordList = wordListService.read()
    }
    
    func showTutorial() {
        
    }
    
}

//MARK: - DataSource

extension WordListPresenter: DataSource {
    
    func numberOfItems() -> Int {
        return wordList.count
    }
    
    func word(atIndex index: IndexPath) -> String? {
        if index.row < wordList.count {
            return wordList[index.row]
        }
        
        return nil
    }
    
    func removeWord(atIndex index: IndexPath) -> Bool {
        if index.row < wordList.count {
            wordList.remove(at: index.row)
            return true
        }
        
        return false
    }
    
}
