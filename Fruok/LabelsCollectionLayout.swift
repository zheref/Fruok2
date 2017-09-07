//
//  LabelsCollectionLayout.swift
//  Fruok
//
//  Created by Matthias Keiser on 18.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

class LabelsCollectionLayout: HorizontalFittingCollectionLayout {

	convenience init() {

		self.init(
			withItemIdension: 0.0,
			interItemMargin: 2.0,
			leadingEdgeMargin: 0.0,
			trailingEdgeMargin: 18.0)
	}

	weak var delegate: LabelsViewModel?
	let kDefaultWidth: CGFloat = 100.0
	var computedWidths: [CGFloat]?
	let kEditingItemWidth: CGFloat = 200.0
	let kAddItemWidth: CGFloat = 92.0

	override func prepare() {

		let nib = NSNib(nibNamed: "LabelItem", bundle: nil)!
		var toplevel: NSArray = []

		guard nib.instantiate(withOwner: nil, topLevelObjects: &toplevel) else {
			self.computedWidths = nil
			return
		}

		guard let prototypeItem: LabelItem = toplevel.filter ({ return $0 is LabelItem }).first as? LabelItem else {
			self.computedWidths = nil
			return
		}

		guard let delegate = self.delegate else {
			self.computedWidths = nil
			return
		}

		self.computedWidths = (0..<delegate.numTotalItems).map {

			if delegate.addItemIndex == $0 {
				return kAddItemWidth
			}

			guard let viewModel = delegate.labelItemViewModel(for: $0) else {
				return self.kDefaultWidth
			}

			if let viewModel = viewModel as? LabelItemViewModel {

				prototypeItem.set(viewModel: viewModel)

				return prototypeItem.view.fittingSize.width

			} else if viewModel is LabelEditingItemViewModel {

				return kEditingItemWidth
			}
			preconditionFailure()
		}
	}

	override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {

		guard let numItems = self.collectionView?.numberOfItems(inSection: 0) else {
			return []
		}

		var attributesArray: [NSCollectionViewLayoutAttributes] = []

		// We are bruteforcing, how many labels can there be?
		for i in 0..<numItems {

			if let attributes = self.layoutAttributesForItem(at: IndexPath(item: i, section: 0)) {
				if attributes.frame.intersects(rect) {
					attributesArray.append(attributes)
				}
			}
		}
		return attributesArray
	}

	func position(for index: Int, computedWidths: [CGFloat]) -> CGFloat {

		let position = computedWidths[0..<index].reduce(CGFloat(0)) { (result, width) -> CGFloat in
			return result + width + kInterItemMargin
		}
		return position
	}

	override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {

		guard let computedWidths = self.computedWidths else {
			return nil
		}

		let position = self.position(for: indexPath.item, computedWidths: computedWidths)

		let viewDimension = (self.vertical ? self.collectionView?.bounds.width : self.collectionView?.bounds.height) ?? 100

		let itemSpan = viewDimension - (kLeadingEdgeMargin + kTrailingEdgeMargin)

		let frame = self.vertical ?
			CGRect(x: kLeadingEdgeMargin, y: position, width: itemSpan, height: kItemDimension) :
			CGRect(x: position, y: kLeadingEdgeMargin, width: computedWidths[indexPath.item], height: itemSpan)

		let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
		attributes.frame = frame

		if hiddenIndexPaths?.contains(indexPath) ?? false {
			attributes.alpha = 0.0
		}

		if self.delegate?.addItemIndex == indexPath.item {
			attributes.zIndex = 1000
		}

		return attributes
	}

	override func layoutAttributesForDropTarget(at pointInCollectionView: NSPoint) -> NSCollectionViewLayoutAttributes? {

		if let attributes = super.layoutAttributesForDropTarget(at: pointInCollectionView) {
			return attributes
		}

		let position = self.vertical ? pointInCollectionView.y : pointInCollectionView.x

		guard let computedWidths = self.computedWidths else {
			return nil
		}

		var dropIndex: Int = 0
		var accumulated: CGFloat = 0
		for (width, index) in zip(computedWidths, 0..<computedWidths.count) {

			accumulated += width

			if accumulated > position {
				dropIndex = index
				break
			}
		}

		guard let collectionView = self.collectionView else {
			return nil
		}

		dropIndex = min(dropIndex, collectionView.numberOfItems(inSection: 0))

		return self.layoutAttributesForInterItemGap(before: IndexPath(item: dropIndex, section: 0))
	}

	override var collectionViewContentSize: NSSize {

		guard let collectionView = self.collectionView else {
			return .zero
		}
		guard let computedWidths = self.computedWidths else {
			return .zero
		}

		let collectionDimension = computedWidths.reduce(CGFloat(kInterItemMargin)) { (sum, width) -> CGFloat in
			return sum + width + kInterItemMargin
		}

		return self.vertical ?
			NSSize(width: collectionView.bounds.width, height: collectionDimension) :
			NSSize(width: collectionDimension, height: collectionView.bounds.height)
	}
}
