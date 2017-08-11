//
//  TasksCollectionVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class TasksCollectionViewController: NSViewController, MVVMView {

	enum ItemIdentifier: String {
		case task
	}

	typealias VIEWMODEL = TasksCollectionViewModel
	private(set) var viewModel: TasksCollectionViewModel?

	static func create() -> TasksCollectionViewController {

		let storyboard = NSStoryboard(name: "TasksCollectionView", bundle: nil)
		let controller = storyboard.instantiateInitialController()
		return controller as! TasksCollectionViewController
	}
	
	@IBOutlet var collectionView: NSCollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
		let nib = NSNib(nibNamed: "KanbanTaskItem", bundle: nil)
		self.collectionView.register(nib, forItemWithIdentifier: ItemIdentifier.task.rawValue)
		self.collectionView.collectionViewLayout = TasksCollectionLayout()
		self.connectVMIfReady()
    }

	internal func set(viewModel: TasksCollectionViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	func connectVM() {

		self.viewModel?.viewActions.observeNext(with: { action in

			switch action {
			case .refreshTasks?:
				self.collectionView.reloadData()

			case .addTasksAtIndexes(let indexSet)?:

				let set = Set(indexSet.map({IndexPath(item: $0, section: 0)}))
				self.collectionView.animator().performBatchUpdates({
					NSAnimationContext.current().allowsImplicitAnimation = true
					self.collectionView.insertItems(at: set)

				}, completionHandler: { _ in


					NSAnimationContext.runAnimationGroup({ context in

						NSAnimationContext.current().allowsImplicitAnimation = true
						self.collectionView.scrollToItems(at: set, scrollPosition: .centeredVertically)
					}, completionHandler: {

						if let indexPath = set.first, let item = self.collectionView.item(at: indexPath) {

							NSApp.sendAction(#selector(KanbanViewController.showTaskDetails(_:)), to: nil, from: item)
						}
					})

					NSAnimationContext.current().allowsImplicitAnimation = true
				})
			case .deleteTasksAtIndexes(let indexSet)?:
				self.collectionView.animator().performBatchUpdates({

					let set = Set(indexSet.map({IndexPath(item: $0, section: 0)}))
					self.collectionView.deleteItems(at: set)

				}, completionHandler: { _ in

				})
			case nil:
				break
			}
		}).dispose(in: bag)
	}
}

extension TasksCollectionViewController: NSCollectionViewDataSource {

	public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

		return self.viewModel?.numTaskStates.value ?? 0
	}

	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		let item =  self.collectionView.makeItem(withIdentifier: ItemIdentifier.task.rawValue, for: indexPath) as! KanbanTaskItem

		if let itemViewModel = self.viewModel?.taskItemViewModel(for: indexPath.item) {
			item.set(viewModel: itemViewModel)
		}
		return item
	}
}

