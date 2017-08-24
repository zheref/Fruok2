//
//  CollectionViewDataSource.swift
//  Fruok
//
//  Created by Matthias Keiser on 13.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

protocol CollectionViewModelClientView: MVVMView {

	var collectionView: NSCollectionView! {get set}
	func executeCollectionViewModelAction(_ action: CollectionViewModelActions?)
	func draggedIndexPaths() -> Set<IndexPath>?
}

extension CollectionViewModelClientView {

	func executeCollectionViewModelAction(_ action: CollectionViewModelActions?) {

		self.collectionView.reloadData()
		return
		
//		switch action {
//		case .refreshTaskStates?:
//			self.collectionView.reloadData()
//
//		case .addTasksAtIndexes(let indexSet)?:
//
//			let set = Set(indexSet.map({IndexPath(item: $0, section: 0)}))
//			self.collectionView.animator().performBatchUpdates({
//
//				NSAnimationContext.current().allowsImplicitAnimation = true
//				self.collectionView.insertItems(at: set)
//
//			}, completionHandler: { _ in
//
//				let liveSet = Set(set.filter{ $0.item < self.collectionView.numberOfItems(inSection: 0) })
//				if liveSet.count > 0 {
//					NSAnimationContext.current().allowsImplicitAnimation = true
//					self.collectionView.scrollToItems(at: liveSet, scrollPosition: .centeredHorizontally)
//				}
//			})
//		case .deleteTasksAtIndexes(let indexSet)?:
//			self.collectionView.animator().performBatchUpdates({
//
//				let set = Set(indexSet.map({IndexPath(item: $0, section: 0)}))
//				self.collectionView.deleteItems(at: set)
//
//			}, completionHandler: nil)
//		case .moveTasks(let mappingDict)?:
//
//			let targetPaths = mappingDict.values.reduce(Set<IndexPath>(), { (set, index) in
//				var setCopy = set
//				setCopy.insert(IndexPath(item: index, section: 0))
//				return setCopy
//			})
//
//			if let draggedIndexPaths = self.draggedIndexPaths() {
//
//				for item in draggedIndexPaths.map({self.collectionView.item(at: $0)}) {
//					item?.view.alphaValue = 0.0
//				}
//				(self.collectionView.collectionViewLayout as? DragAndDropCollectionLayout)?.hiddenIndexPaths = targetPaths
//			}
//			self.collectionView.animator().performBatchUpdates({
//
//				for (source, target) in mappingDict {
//					self.collectionView.moveItem(at: IndexPath(item: source, section: 0), to: IndexPath(item: target, section: 0))
//				}
//			}, completionHandler: { _ in
//
//				(self.collectionView.collectionViewLayout as? DragAndDropCollectionLayout)?.hiddenIndexPaths = nil
//				self.collectionView.collectionViewLayout?.invalidateLayout()
//			})
//		case nil:
//			break
//		}
	}

}
