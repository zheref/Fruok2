//
//  DragAndDropCollectionLayout.swift
//  Fruok
//
//  Created by Matthias Keiser on 14.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

class DragAndDropCollectionLayout: NSCollectionViewLayout {

	var hiddenIndexPaths: Set<IndexPath>?
}

class HorizontalFittingCollectionLayout: VerticalFittingCollectionLayout {

	override var scrollDirection: NSCollectionViewScrollDirection {

		return .horizontal
	}
}

class VerticalFittingCollectionLayout: DragAndDropCollectionLayout {

	let kItemDimension: CGFloat
	let kInterItemMargin: CGFloat
	let kLeadingEdgeMargin: CGFloat
	let kTrailingEdgeMargin: CGFloat

	required init(withItemIdension itemDimension: CGFloat, interItemMargin: CGFloat, leadingEdgeMargin: CGFloat, trailingEdgeMargin: CGFloat) {

		self.kItemDimension = itemDimension
		self.kInterItemMargin = interItemMargin
		self.kLeadingEdgeMargin = leadingEdgeMargin
		self.kTrailingEdgeMargin = trailingEdgeMargin

		super.init()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

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

		let position = (CGFloat(indexPath.item) * kItemDimension) + (CGFloat(indexPath.item + 1)) * kInterItemMargin

		let viewDimension = (self.vertical ? self.collectionView?.bounds.width : self.collectionView?.bounds.height) ?? 100

		let itemSpan = viewDimension - (kLeadingEdgeMargin + kTrailingEdgeMargin)

		let frame = self.vertical ?
			CGRect(x: kLeadingEdgeMargin, y: position, width: itemSpan, height: kItemDimension) :
			CGRect(x: position, y: kLeadingEdgeMargin, width: kItemDimension, height: itemSpan)

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

		if self.vertical {
			frame.origin.y -= kInterItemMargin
			frame.size.height = kInterItemMargin
		} else {
			frame.origin.x -= kInterItemMargin
			frame.size.width = kInterItemMargin

		}

		let attributes = NSCollectionViewLayoutAttributes(forInterItemGapBefore: indexPath)
		attributes.frame = frame

		return attributes
	}

	override func layoutAttributesForDropTarget(at pointInCollectionView: NSPoint) -> NSCollectionViewLayoutAttributes? {

		if let attributes = super.layoutAttributesForDropTarget(at: pointInCollectionView) {
			return attributes
		}

		let position = self.vertical ? pointInCollectionView.y : pointInCollectionView.x

		var index = Int(floor((position - kInterItemMargin) / (kItemDimension + kInterItemMargin))) + 1

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

		let collectionDimension = (CGFloat(numItems) * kItemDimension) + (CGFloat(numItems + 1)) * kInterItemMargin

		return self.vertical ?
			NSSize(width: collectionView.bounds.width, height: collectionDimension) :
			NSSize(width: collectionDimension, height: collectionView.bounds.height)
	}

	var scrollDirection: NSCollectionViewScrollDirection {

		return .vertical
	}

	override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
		return true
	}
	
	var vertical: Bool {
		return self.scrollDirection == .vertical
	}
}
