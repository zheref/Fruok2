//
//  KanbanVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class KanbanViewController: NSViewController, MVVMView {

	enum ItemIdentifier: String {
		case task
	}
	@IBOutlet var collectionView: NSCollectionView!

	typealias VIEWMODEL = KanbanViewModel
	private(set) var viewModel: KanbanViewModel?
	func set(viewModel: KanbanViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}
    override func viewDidLoad() {
        super.viewDidLoad()
		let nib = NSNib(nibNamed: "KanbanTaskStateItem", bundle: nil)
		self.collectionView.register(nib, forItemWithIdentifier: ItemIdentifier.task.rawValue)
		self.collectionView.collectionViewLayout = KanbanCollectionLayout()
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.viewActions.observeNext(with: { action in

			switch action {
			case .refreshTaskStates?:
				self.collectionView.reloadData()
			case nil:
				break
			}
		}).dispose(in: bag)
	}

	@IBAction func addTask(_ sender: Any) {

		self.viewModel?.addTask()
	}
	
}

extension KanbanViewController: NSCollectionViewDataSource {

	public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

		return self.viewModel?.numTaskStates.value ?? 0
	}

	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		return self.collectionView.makeItem(withIdentifier: ItemIdentifier.task.rawValue, for: indexPath)
	}
}
