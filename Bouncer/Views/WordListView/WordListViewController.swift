//
//  WordListViewController.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/10/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import UIKit

protocol WordListViewControllerDelegate: class {
    func wordListViewControllerDidTapAddButton()
    func wordListViewControllerDidAppear()
    func wordListViewControllerDidTapHelpButton()
}

final class WordListViewController: UITableViewController, WordListView, Storyboarded {
    
    var viewTitleText: String?
    var removeButtonText: String?
    var removeButtonBgColor: UIColor?
    
    var presenter: WordListPresenter?
    var delegate: WordListViewControllerDelegate?
    
    //MARK: - Actions

    @IBAction func addWord(_ sender: UIBarButtonItem) {
        delegate?.wordListViewControllerDidTapAddButton()
    }
    
    @IBAction func showHelp(_ sender: Any) {
        delegate?.wordListViewControllerDidTapHelpButton()
    }
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter?.attachView(view: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.readWordList()
        tableView.reloadData()        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.wordListViewControllerDidAppear()
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.numberOfItems() ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell", for: indexPath)
        cell.textLabel?.text = presenter?.word(atIndex: indexPath)
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: removeButtonText) { [weak self] action, view, closure in
            guard let strongSelf = self else { return }
            if let success = strongSelf.presenter?.removeWord(atIndex: indexPath) {
                if success {
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                    tableView.endUpdates()
                    strongSelf.saveWordList()
                    closure(true)
                }
                else {
                    closure(false)
                }
            }
        }
        
        deleteAction.backgroundColor = removeButtonBgColor
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        
        return configuration
    }
    
    // MARK: Actions
    
    private func saveWordList() {
        presenter?.saveWordList()
    }
}
