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

class KanbanViewController: NSViewController, MVVMView {

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
    override func viewDidLoad() {
        super.viewDidLoad()
		let nib = NSNib(nibNamed: "KanbanTaskStateItem", bundle: nil)
		self.collectionView.register(nib, forItemWithIdentifier: ItemIdentifier.task.rawValue)
		self.collectionView.collectionViewLayout = KanbanCollectionLayout()
		self.collectionView.register(forDraggedTypes: [UTI.fruokTaskState.rawValue])
		self.collectionView.setDraggingSourceOperationMask(.move, forLocal: true)
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.viewActions.observeNext(with: { action in

			switch action {
			case .refreshTaskStates?:
				self.collectionView.reloadData()

			case .addTasksAtIndexes(let indexSet)?:

				let set = Set(indexSet.map({IndexPath(item: $0, section: 0)}))
				self.collectionView.animator().performBatchUpdates({

					NSAnimationContext.current().allowsImplicitAnimation = true
					self.collectionView.insertItems(at: set)

				}, completionHandler: { _ in
					NSAnimationContext.current().allowsImplicitAnimation = true
					self.collectionView.scrollToItems(at: set, scrollPosition: .centeredHorizontally)
				})
			case .deleteTasksAtIndexes(let indexSet)?:
				self.collectionView.animator().performBatchUpdates({

					let set = Set(indexSet.map({IndexPath(item: $0, section: 0)}))
					self.collectionView.deleteItems(at: set)

				}, completionHandler: nil)
			case .moveTasks(let mappingDict)?:

				let targetPaths = mappingDict.values.reduce(Set<IndexPath>(), { (set, index) in
					var setCopy = set
					setCopy.insert(IndexPath(item: index, section: 0))
					return setCopy
				})

				if let draggedIndexPaths = self.draggedIndexPaths {

					for item in draggedIndexPaths.map({self.collectionView.item(at: $0)}) {
						item?.view.alphaValue = 0.0
					}
					(self.collectionView.collectionViewLayout as? KanbanCollectionLayout)?.hiddenIndexPaths = targetPaths
				}
				self.collectionView.animator().performBatchUpdates({

					for (source, target) in mappingDict {
						self.collectionView.moveItem(at: IndexPath(item: source, section: 0), to: IndexPath(item: target, section: 0))
					}
				}, completionHandler: { _ in

					(self.collectionView.collectionViewLayout as? KanbanCollectionLayout)?.hiddenIndexPaths = nil
					self.collectionView.collectionViewLayout?.invalidateLayout()
				})
			case nil:
				break
			}
		}).dispose(in: bag)
	}

	@IBAction func addTask(_ sender: Any) {

		self.viewModel?.addTask()
	}

	@IBAction func deleteTask(_ sender: NSCollectionViewItem) {

		if let index = self.collectionView.indexPath(for: sender)?.item {
			self.viewModel?.deleteTask(at: index)
		}
	}

	@IBAction func showTaskDetails(_ sender: Any?) {

		guard let taskItem = sender as? KanbanTaskItem, let itemViewModel = taskItem.viewModel else {
			return
		}
		let taskViewModel = itemViewModel.viewModelForTaskDetail()
		let detailController = TaskDetailViewController()
		detailController.set(viewModel: taskViewModel)
		self.presentViewController(detailController, asPopoverRelativeTo: taskItem.view.bounds, of: taskItem.view, preferredEdge: .maxX, behavior: .semitransient)
	}


	var draggedIndexPaths: Set<IndexPath>?
}

extension KanbanViewController: NSCollectionViewDataSource {

	public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

		return self.viewModel?.numTaskStates.value ?? 0
	}

	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		let item =  self.collectionView.makeItem(withIdentifier: ItemIdentifier.task.rawValue, for: indexPath) as! KanbanTaskStateItem

		if let itemViewModel = self.viewModel?.taskStateViewModel(for: indexPath.item) {
			item.set(viewModel: itemViewModel)
		}
		return item
	}
}

extension KanbanViewController: NSCollectionViewDelegate {

	func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
		return indexPaths
	}

	// Dragging Source
	func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
		return true
	}

	func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {

		return self.viewModel?.pasteboardItemForTastState(at: indexPath.item)
	}

	func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {

		self.draggedIndexPaths = indexPaths
	}

	func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {

		self.draggedIndexPaths = nil
	}

	func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {

		if let itemFrame = self.collectionView.collectionViewLayout?.layoutAttributesForItem(at: proposedDropIndexPath.pointee as IndexPath)?.frame {

			let location = self.collectionView.convert(draggingInfo.draggingLocation(), from: nil)

			if itemFrame.midX < location.x {

				let next = IndexPath(item: proposedDropIndexPath.pointee.item + 1, section: proposedDropIndexPath.pointee.section)
				proposedDropIndexPath.pointee = next as NSIndexPath
			}

		}


		proposedDropOperation.pointee = .before
		draggingInfo.animatesToDestination = true

		return .move
	}

	func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionViewDropOperation) -> Bool {


		guard let items = draggingInfo.draggingPasteboard().pasteboardItems else {
			return false
		}

		let taskStateItems = items.filter { item in

			return item.availableType(from: [UTI.fruokTaskState.rawValue]) != nil
		}

		let objectURIStrings: [String] = taskStateItems.flatMap { item in

			item.string(forType: UTI.fruokTaskState.rawValue)
		}

		guard objectURIStrings.count == taskStateItems.count else {
			return false
		}

		if dropOperation == .before {

			let draggedIndexes = self.viewModel!.objectIndexes(for: objectURIStrings)
			let targetIndex = KanbanViewModel.actualDropIndex(forDraggedIndexes: draggedIndexes, proposedIndex: indexPath.item, withNumStates: self.collectionView.numberOfItems(inSection: 0))
			draggingInfo.enumerateDraggingItems(options: [.clearNonenumeratedImages], for: self.collectionView, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (item, index, stop) in

				item.draggingFrame = (self.collectionView.collectionViewLayout?.layoutAttributesForItem(at: IndexPath(item: targetIndex, section: 0)))?.frame ?? item.draggingFrame
			})
			return self.viewModel?.moveTaskStates(withURIStrings: objectURIStrings, beforeIndexPath: indexPath) ?? false
		} else {
			return false
		}
	}

}

extension KanbanViewController {

	func writeItems(at indexPaths: Set<IndexPath>, toPasteboard pasteboard: NSPasteboard) -> Bool {

		let items: [NSPasteboardWriting] = indexPaths.map ({

			"\($0.item)" as NSString
		})

		pasteboard.clearContents()
		return pasteboard.writeObjects(items)
	}
}
