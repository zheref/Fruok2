//
//  KanbanVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

extension UTI {

	static let fruokTaskState = UTI(rawValue: "com.tristan.fruok.taskState")
}

extension TaskState: NSPasteboardWriting {

	public func writableTypes(for pasteboard: NSPasteboard) -> [String] {
		return [UTI.fruokTaskState.rawValue]
	}

	public func pasteboardPropertyList(forType type: String) -> Any? {

		switch UTI(rawValue: type) {

		case UTI.fruokTaskState:
			return self.objectID.uriRepresentation().absoluteString

		default:
			return nil
		}
	}
}

class KanbanViewController: NSViewController, CollectionViewModelClientView {

	enum ItemIdentifier: String {
		case task
	}

	let kTaskStateDragType = "kTaskStateDragType"

	@IBOutlet var collectionView: NSCollectionView!

	typealias VIEWMODEL = KanbanViewModel
	private(set) var viewModel: KanbanViewModel?

	func set(viewModel: KanbanViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	var collectionViewDelegate: CollectionViewDragAndDropDelegate<VIEWMODEL>? {
		didSet {
			self.collectionView.delegate = self.collectionViewDelegate
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		let nib = NSNib(nibNamed: "KanbanTaskStateItem", bundle: nil)
		self.collectionView.register(nib, forItemWithIdentifier: ItemIdentifier.task.rawValue)
		self.collectionView.collectionViewLayout = KanbanCollectionLayout()
		self.collectionView.register(forDraggedTypes: [UTI.fruokTaskState.rawValue])
		self.collectionView.setDraggingSourceOperationMask(.move, forLocal: true)
		self.connectVMIfReady()
    }

	func draggedIndexPaths() -> Set<IndexPath>? {

		return self.collectionViewDelegate?.draggedIndexPaths
	}

	func connectVM() {

		self.viewModel?.viewActions.observeNext(with: { action in

			self.executeCollectionViewModelAction(action)

		}).dispose(in: bag)

		self.collectionViewDelegate = CollectionViewDragAndDropDelegate<VIEWMODEL>(withViewModel: self.viewModel!, collectionView: collectionView, draggingUTI: UTI.fruokTaskState)

		self.viewModel?.showTaskDeleteDialog.observeNext(with: { dialogViewModel in

			if let dialogViewModel = dialogViewModel {

				let confirmationDialog = DeleteTaskStateConfirmationDialog()
				confirmationDialog.set(viewModel: dialogViewModel)
				self.presentViewControllerAsSheet(confirmationDialog)
			}
		}).dispose(in: bag)
	}

	@IBAction func addTaskState(_ sender: Any) {

		self.viewModel?.addTaskState()
	}

	@IBAction func deleteTaskStateAction(_ sender: NSCollectionViewItem) {

		if let index = self.collectionView.indexPath(for: sender)?.item {
			self.viewModel?.deleteTaskState(at: index)
		}
	}

	@IBAction func showTaskDetails(_ sender: Any?) {

		guard let taskItem = sender as? KanbanTaskItem, let itemViewModel = taskItem.viewModel else {
			return
		}
		let taskViewModel = itemViewModel.viewModelForTaskDetail()
		let detailController = TaskDetailViewController()
		detailController.set(viewModel: taskViewModel)
		self.presentViewController(detailController, animator: DetailPresentationAnimator())
	}
}

extension KanbanViewController: NSCollectionViewDataSource {

	public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

		return self.viewModel?.numCollectionObjects.value ?? 0
	}

	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		let item =  self.collectionView.makeItem(withIdentifier: ItemIdentifier.task.rawValue, for: indexPath) as! KanbanTaskStateItem

		if let itemViewModel = self.viewModel?.taskStateViewModel(for: indexPath.item) {
			item.set(viewModel: itemViewModel)
		}
		return item
	}
}
