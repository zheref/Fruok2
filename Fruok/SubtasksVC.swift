//
//  SubtasksViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 16.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class SubtasksTableView: NSTableView {

	@IBAction override func cancelOperation(_ sender: Any?) {

		var nextResponder: NSResponder? = self.nextResponder

		while nextResponder != nil {

			if nextResponder!.responds(to: #selector(cancelOperation(_:))) {
				nextResponder?.cancelOperation(sender)
				break
			}
			nextResponder = nextResponder?.nextResponder
		}
	}
}
class SubtasksViewController: NSViewController, MVVMView {

	@IBOutlet var tableView: NSTableView!

	@IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!

	typealias MVVMViewModel = SubtasksViewModel
	private(set) var viewModel: SubtasksViewModel?
	internal func set(viewModel: SubtasksViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {
		self.init(nibName: "SubtasksVC", bundle: nil)!
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.action = #selector(SubtasksViewController.tableAction(_ :))
		self.tableView.doubleAction = #selector(SubtasksViewController.edit(_ :))
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.viewActions.observeNext(with: { [weak self] action in

			guard let mySelf = self else { return }
			mySelf.executeCollectionViewModelAction(action)

			if let scrollView = mySelf.tableView.enclosingScrollView {

				let size = NSSize(width: mySelf.tableView.frame.size.width, height: CGFloat(mySelf.tableView.numberOfRows) * (mySelf.tableView.rowHeight + mySelf.tableView.intercellSpacing.height))
				let scrollViewSize = scrollView.tr_sizeThatFits(contentSize: size, controlSize: .regular)
				mySelf.tableViewHeightConstraint.constant = scrollViewSize.height
			}
			
		}).dispose(in: bag)
	}

	func executeCollectionViewModelAction(_ action: CollectionViewModelActions?) {

		switch action {
		case .refreshTaskStates?:
			self.tableView.reloadData()

		case .addTasksAtIndexes(let indexSet)?:

			self.tableView.insertRows(at:indexSet, withAnimation: .effectFade)
			self.tableView.scrollRowToVisible(indexSet.last!)

		case .deleteTasksAtIndexes(let indexSet)?:

			self.tableView.removeRows(at:indexSet, withAnimation: .effectFade)

		case .moveTasks(let mappingDict)?:

			self.tableView.beginUpdates()
			for (oldIndex, newIndex) in mappingDict {

				self.tableView.moveRow(at: oldIndex, to :newIndex)
			}
			self.tableView.endUpdates()
		case nil:
			break
		}
	}

	@IBAction func tableAction(_ sender: Any) {

		if self.tableView.clickedRow == self.viewModel?.addButtonIndex {
			self.viewModel?.userWantsAddSubtask()
		}
	}
	
	@IBAction func addSubtask(_ sender: Any) {

		self.viewModel?.userWantsAddSubtask()
	}

	@IBAction func delete(_ sender: Any) {

		let clickedRow = self.tableView.clickedRow

		guard clickedRow >= 0 else { return }

		self.viewModel?.userWantsDeleteSubtask(at: clickedRow)
	}
	
	@IBAction func edit(_ sender: Any) {

		let clickedRow = self.tableView.clickedRow

		guard clickedRow >= 0 else { return }

		self.viewModel?.userWantsEditSubtask(at: clickedRow)
	}

	@IBAction override func cancelOperation(_ sender: Any?) {

		self.viewModel?.userWantsCancelEdit()
	}


}

extension SubtasksViewController: NSTableViewDataSource, NSTableViewDelegate {

	enum CellName: String {
		case SubtaskCell
		case AddSubtaskCell
	}

	func numberOfRows(in tableView: NSTableView) -> Int {

		return self.viewModel?.numCollectionObjects.value ?? 0
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		if self.viewModel?.addButtonIndex == row {

			let cell = self.tableView.make(withIdentifier: CellName.AddSubtaskCell.rawValue, owner: self)
			return cell
		}

		let cell = self.tableView.make(withIdentifier: CellName.SubtaskCell.rawValue, owner: self) as! SubtaskCell
		let viewModel = self.viewModel!.subtaskViewModel(for: row)
		cell.set(viewModel: viewModel)
		return cell
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		return false
	}
}
