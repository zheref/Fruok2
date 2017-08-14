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

	let vertical: Bool
	let viewModel: VIEWMODEL
	let collectionView: NSCollectionView
	let draggingUTI: UTI

	init(withViewModel viewModel: VIEWMODEL, collectionView: NSCollectionView, draggingUTI: UTI) {

		self.vertical = true
		self.viewModel = viewModel
		self.collectionView = collectionView
		self.draggingUTI = draggingUTI
	}

	init(horizontalWithViewModel viewModel: VIEWMODEL, collectionView: NSCollectionView, draggingUTI: UTI) {

		self.vertical = false
		self.viewModel = viewModel
		self.collectionView = collectionView
		self.draggingUTI = draggingUTI
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

			let shift = self.vertical ? (itemFrame.midX < location.x) : (itemFrame.midY < location.y)

			if shift {

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

			return item.availableType(from: [self.draggingUTI.rawValue]) != nil
		}

		let objectURIStrings: [String] = taskStateItems.flatMap { item in

			item.string(forType: self.draggingUTI.rawValue)
		}

		guard objectURIStrings.count == taskStateItems.count else {
			return false
		}

		if dropOperation == .before {

			if let targetIndexes = self.viewModel.dropIndex(forDraggedURIs: objectURIStrings, proposedIndex: indexPath.item) {
				draggingInfo.enumerateDraggingItems(options: [.clearNonenumeratedImages], for: self.collectionView, classes: [NSPasteboardItem.self], searchOptions: [:], using: { (item, index, stop) in

					if let uri = (item.item as! NSPasteboardItem).string(forType: self.draggingUTI.rawValue) {
						if let targetIndex = targetIndexes[uri] {
							item.draggingFrame = self.collectionView.collectionViewLayout?.layoutAttributesForItem(at: IndexPath(item: targetIndex, section: 0))?.frame ?? item.draggingFrame
						}
					}
				})
			}
			return self.viewModel.moveObjects(withURIStrings: objectURIStrings, beforeIndexPath: indexPath)
		} else {
			return false
		}
	}
}
