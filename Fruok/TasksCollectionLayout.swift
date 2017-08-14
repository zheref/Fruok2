//
//  TasksCollectionLayout.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class TasksCollectionLayout: DragAndDropCollectionLayout {

	let kItemHeight: CGFloat = 130.0
	let kHorizontalMargin: CGFloat = 10.0
	let kVerticalMargin: CGFloat = 10.0

	override func prepare() {

	}
	override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {

		var attributes: [NSCollectionViewLayoutAttributes] = []

		guard let collectionView = self.collectionView else { return []}

		for item in 0..<collectionView.numberOfItems(inSection: 0) {

			if let attribute = self.layoutAttributesForItem(at: IndexPath(item: item, section: 0)) {
				attributes.append(attribute)
			}
		}

		return attributes
	}

	override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {

		let x = kHorizontalMargin
		let y = (CGFloat(indexPath.item) * kItemHeight) + (CGFloat(indexPath.item + 1)) * kVerticalMargin

		let viewWidth = self.collectionView?.bounds.width ?? 100

		let width = viewWidth - (2 * kHorizontalMargin)

		let frame = CGRect(x: x, y: y, width: width, height: kItemHeight)

		let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
		attributes.frame = frame

		if hiddenIndexPaths?.contains(indexPath) ?? false {
			attributes.alpha = 0.0
		}

		return attributes
	}

	override func layoutAttributesForInterItemGap(before indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {

		guard let itemAttributes = self.layoutAttributesForItem(at: indexPath) else {
			return nil
		}

		var frame = itemAttributes.frame
		frame.origin.y -= kVerticalMargin
		frame.size.height = kVerticalMargin

		let attributes = NSCollectionViewLayoutAttributes(forInterItemGapBefore: indexPath)
		attributes.frame = frame

		return attributes
	}

	override func layoutAttributesForDropTarget(at pointInCollectionView: NSPoint) -> NSCollectionViewLayoutAttributes? {

		if let attributes = super.layoutAttributesForDropTarget(at: pointInCollectionView) {
			return attributes
		}

		var index = Int(floor((pointInCollectionView.y - kVerticalMargin) / (kItemHeight + kVerticalMargin))) + 1

		guard let collectionView = self.collectionView else {
			return nil
		}

		index = min(index, collectionView.numberOfItems(inSection: 0))

		return self.layoutAttributesForInterItemGap(before: IndexPath(item: index, section: 0))
	}

	override var collectionViewContentSize: NSSize {

		guard let collectionView = self.collectionView else {
			return .zero
		}

		let numItems = collectionView.numberOfItems(inSection: 0)

		let height = (CGFloat(numItems) * kItemHeight) + (CGFloat(numItems + 1)) * kVerticalMargin

		return NSSize(width: collectionView.bounds.height, height: height)
	}

	var scrollDirection: NSCollectionViewScrollDirection {

		return .vertical
	}

	override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
		return true
	}
	
}
