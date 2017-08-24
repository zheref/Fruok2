//
//  TasksCollectionVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

extension UTI {

	static let fruokTask = UTI(rawValue: "com.tristan.fruok.task")
}

extension Task: NSPasteboardWriting {

	public func writableTypes(for pasteboard: NSPasteboard) -> [String] {
		return [UTI.fruokTask.rawValue]
	}

	public func pasteboardPropertyList(forType type: String) -> Any? {

		switch UTI(rawValue: type) {

		case UTI.fruokTask:
			return self.objectID.uriRepresentation().absoluteString

		default:
			return nil
		}
	}
}

class TasksCollectionViewController: NSViewController, CollectionViewModelClientView {

	enum ItemIdentifier: String {
		case task
	}

	typealias VIEWMODEL = TasksCollectionViewModel
	private(set) var viewModel: TasksCollectionViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}

	static func create() -> TasksCollectionViewController {

		let storyboard = NSStoryboard(name: "TasksCollectionView", bundle: nil)
		let controller = storyboard.instantiateInitialController()
		return controller as! TasksCollectionViewController
	}
	var collectionViewDelegate: CollectionViewDragAndDropDelegate<VIEWMODEL>? {
		didSet {
			self.collectionView.delegate = self.collectionViewDelegate
		}
	}
	func draggedIndexPaths() -> Set<IndexPath>? {

		return self.collectionViewDelegate?.draggedIndexPaths
	}


	@IBOutlet var collectionView: NSCollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
		let nib = NSNib(nibNamed: "KanbanTaskItem", bundle: nil)
		self.collectionView.register(nib, forItemWithIdentifier: ItemIdentifier.task.rawValue)
		self.collectionView.register(forDraggedTypes: [UTI.fruokTask.rawValue])
		self.collectionView.setDraggingSourceOperationMask(.move, forLocal: true)
		self.collectionView.collectionViewLayout = TasksCollectionLayout()
		self.connectVMIfReady()
    }

	internal func set(viewModel: TasksCollectionViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	let reuseBag = DisposeBag()

	func connectVM() {

		self.viewModel?.viewActions.observeNext(with: { action in

			self.executeCollectionViewModelAction(action)
		}).dispose(in: reuseBag)

		self.collectionViewDelegate = CollectionViewDragAndDropDelegate<VIEWMODEL>(horizontalWithViewModel: self.viewModel!, collectionView: collectionView, draggingUTI: UTI.fruokTask)

		self.viewModel?.showDetailsForTaskAtIndex.observeNext(with: { taskIndex in

			// We need to dispatch async, because just after item creation,
			// scrollToItems(at:scrollPosition:) fails

			DispatchQueue.main.async {

				guard let taskIndex = taskIndex, taskIndex < self.collectionView.numberOfItems(inSection: 0) else {
					return
				}

				let actionBlock: (NSCollectionViewItem?) -> Void = { item in

					if item != nil {
						NSApp.sendAction(#selector(KanbanViewController.showTaskDetails(_:)), to: nil, from: item)
					}
				}

				let indexPath = IndexPath(item: taskIndex, section: 0)
				if let item = self.collectionView.item(at: indexPath) {

					actionBlock(item)
				} else {

					NSAnimationContext.runAnimationGroup({ context in
						self.collectionView.animator().scrollToItems(at: Set([indexPath]), scrollPosition:[.centeredVertically])
					}, completionHandler: {
						actionBlock(self.collectionView.item(at: indexPath))
					})
				}
			}
		}).dispose(in: reuseBag)

	}
}

extension TasksCollectionViewController: NSCollectionViewDataSource {

	public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

		return self.viewModel?.numCollectionObjects.value ?? 0
	}

	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		let item =  self.collectionView.makeItem(withIdentifier: ItemIdentifier.task.rawValue, for: indexPath) as! KanbanTaskItem

		if let itemViewModel = self.viewModel?.taskItemViewModel(for: indexPath.item) {
			item.set(viewModel: itemViewModel)
		}
		return item
	}
}

