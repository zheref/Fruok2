//
//  CollectionDelegateDragAndDrop.swift
//  Fruok
//
//  Created by Matthias Keiser on 13.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import Bond

class CollectionViewDragAndDropDelegate<VIEWMODEL: CollectionDragAndDropViewModel>: NSObject, NSCollectionViewDelegate {

	let viewModel: VIEWMODEL
	let collectionView: NSCollectionView

	init(withViewModel viewModel: VIEWMODEL, collectionView: NSCollectionView) {

		self.viewModel = viewModel
		self.collectionView = collectionView
	}

	var draggedIndexPaths: Set<IndexPath>?

	func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
		return indexPaths
	}

	// Dragging Source
	func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
		return true
	}

	func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {

		return self.viewModel.pasteboardItemForTastState(at: indexPath.item)
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

			let draggedIndexes = self.viewModel.objectIndexes(for: objectURIStrings)
			let targetIndex = KanbanViewModel.actualDropIndex(forDraggedIndexes: draggedIndexes, proposedIndex: indexPath.item, withNumStates: self.collectionView.numberOfItems(inSection: 0))
			draggingInfo.enumerateDraggingItems(options: [.clearNonenumeratedImages], for: self.collectionView, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (item, index, stop) in

				item.draggingFrame = (self.collectionView.collectionViewLayout?.layoutAttributesForItem(at: IndexPath(item: targetIndex, section: 0)))?.frame ?? item.draggingFrame
			})
			return self.viewModel.moveObjects(withURIStrings: objectURIStrings, beforeIndexPath: indexPath)
		} else {
			return false
		}
	}
}
