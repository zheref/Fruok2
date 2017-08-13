//
//  KanbanCollectionLayout.swift
//  Fruok
//
//  Created by Matthias Keiser on 09.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class KanbanCollectionLayout: NSCollectionViewLayout {

	let kItemWidth: CGFloat = 200.0
	let kHorizontalMargin: CGFloat = 10.0
	let kTopMargin: CGFloat = 10.0
	let kBottomMargin: CGFloat = 10.0

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

	var hiddenIndexPaths: Set<IndexPath>?

	override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {

		let x = (CGFloat(indexPath.item) * kItemWidth) + (CGFloat(indexPath.item + 1)) * kHorizontalMargin
		let y = kTopMargin

		let viewHeight = self.collectionView?.bounds.height ?? 100

		let height = viewHeight - (kTopMargin + kBottomMargin)

		let frame = CGRect(x: x, y: y, width: kItemWidth, height: height)

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
		frame.origin.x -= kHorizontalMargin
		frame.size.width = kHorizontalMargin

		let attributes = NSCollectionViewLayoutAttributes(forInterItemGapBefore: indexPath)
		attributes.frame = frame

		return attributes
	}

	override func layoutAttributesForDropTarget(at pointInCollectionView: NSPoint) -> NSCollectionViewLayoutAttributes? {

		if let attributes = super.layoutAttributesForDropTarget(at: pointInCollectionView) {
			return attributes
		}

		var index = Int(floor((pointInCollectionView.x - kHorizontalMargin) / (kItemWidth + kHorizontalMargin))) + 1

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

		let width = (CGFloat(numItems) * kItemWidth) + (CGFloat(numItems + 1)) * kHorizontalMargin

		return NSSize(width: width, height: collectionView.bounds.height)
	}

	var scrollDirection: NSCollectionViewScrollDirection {

		return .horizontal
	}

	override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
		return true
	}

}
