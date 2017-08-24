//
//  LabelsVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 18.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class LabelsViewController: NSViewController, CollectionViewModelClientView {

	enum ItemIdentifier: String {
		case label
		case editingLabel
		case addLabelItem
	}

	@IBOutlet var collectionView: NSCollectionView!
	typealias VIEWMODEL = LabelsViewModel

	private(set) var viewModel: LabelsViewModel?
	func set(viewModel: LabelsViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {
		self.init(nibName: "LabelsVC", bundle: nil)!
	}

	var collectionViewDelegate: CollectionViewDragAndDropDelegate<LabelsViewModel>? {
		didSet {
			self.collectionView.delegate = self.collectionViewDelegate
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		let nib = NSNib(nibNamed: "LabelItem", bundle: nil)
		self.collectionView.register(nib, forItemWithIdentifier: ItemIdentifier.label.rawValue)
		let editingNib = NSNib(nibNamed: "LabelEditingItem", bundle: nil)
		self.collectionView.register(editingNib, forItemWithIdentifier: ItemIdentifier.editingLabel.rawValue)
		let addNib = NSNib(nibNamed: "LabelAddItem", bundle: nil)
		self.collectionView.register(addNib, forItemWithIdentifier: ItemIdentifier.addLabelItem.rawValue)
		self.connectVMIfReady()
    }

	func draggedIndexPaths() -> Set<IndexPath>? {

		return self.collectionViewDelegate?.draggedIndexPaths
	}

	func connectVM() {

		let layout = LabelsCollectionLayout()
		layout.delegate = self.viewModel!
		self.collectionView.collectionViewLayout = layout

		self.viewModel?.viewActions.observeNext(with: { [weak self] action in

			self?.executeCollectionViewModelAction(action)
		}).dispose(in: bag)
	}

	@IBAction func addLabel(_ sender: Any) {

		self.viewModel?.userWantsAddLabel()
	}

	@IBAction func editLabel(_ sender: LabelItem) {

		guard let index = self.collectionView.indexPath(for: sender) else {
			return
		}

		self.viewModel?.userWantsEditLabel(at: index.item)
	}

	@IBAction func deleteLabel(_ sender: LabelItem) {

		guard let index = self.collectionView.indexPath(for: sender) else {
			return
		}

		self.viewModel?.userWantsDeleteLabel(at: index.item)
	}

	@IBAction func cancelEditLabel(_ sender: Any?) {

		self.viewModel?.userWantsCancelEditLabel()
	}

	@IBAction func commitEditLabel(_ sender: LabelEditingCell?) {

		if let editViewModel = sender?.viewModel {
			self.viewModel?.userWantsCommitEditLabel(with: editViewModel)
		}
	}

	@IBAction func setExistingLabel(_ sender: LabelEditingCell?) {

		guard let editViewModel = sender?.viewModel else {
			return
		}
		self.viewModel?.userWantsSetExisintLabelAtEditingPosition(editViewModel: editViewModel)
	}

}

extension LabelsViewController: NSCollectionViewDataSource {

	public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

		return self.viewModel?.numTotalItems ?? 0
	}

	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

		if indexPath.item == self.viewModel?.addItemIndex {

			let item = self.collectionView.makeItem(withIdentifier: ItemIdentifier.addLabelItem.rawValue, for: indexPath)
			return item
		}

		if indexPath.item == self.viewModel?.indexBeingEdited.value {
			let item = self.collectionView.makeItem(withIdentifier: ItemIdentifier.editingLabel.rawValue, for: indexPath) as! LabelEditingCell
			if let viewModel = self.viewModel?.labelItemViewModel(for: indexPath.item) as? LabelEditingItemViewModel {
				item.set(viewModel: viewModel)
			}

			return item
		}
		
		let item =  self.collectionView.makeItem(withIdentifier: ItemIdentifier.label.rawValue, for: indexPath) as! LabelItem

		if let itemViewModel = self.viewModel?.labelItemViewModel(for: indexPath.item) as? LabelItemViewModel {
			item.set(viewModel: itemViewModel)
		}
		return item
	}
}
