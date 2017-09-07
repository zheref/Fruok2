//
//  AttachmentSelectorViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class AttachmentSelectorViewController: NSViewController, MVVMView {

	@IBOutlet var tableView: NSTableView!
	@IBOutlet var okButton: NSButton!


	convenience init() {
		self.init(nibName: "AttachmentSelectorVC", bundle: nil)!
	}

	typealias VIEWMODEL = AttachmentSelectorViewModel
	private(set) var viewModel: AttachmentSelectorViewModel?
	internal func set(viewModel: AttachmentSelectorViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.doubleAction = #selector(AttachmentSelectorViewController.doIt(_:))
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.attachments.observeNext(with: { [weak self] attachments in

			self?.tableView.reloadData()
		}).dispose(in: bag)
	}

	@IBAction func cancel(_ sender: Any) {

		self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSModalResponseStop)
	}

	@IBAction func doIt(_ sender: Any) {

		self.viewModel?.userWantsAttachAttachments(at: self.tableView.selectedRowIndexes)
		self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSModalResponseOK)
	}
	
	@IBAction override func cancelOperation(_ sender: Any?) {

		self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSModalResponseStop)
	}
}

extension AttachmentSelectorViewController: NSTableViewDataSource, NSTableViewDelegate {

	enum ColumnName: String, OptionalRawValueRepresentable {
		case Preview
		case Task
		case Name
	}

	func numberOfRows(in tableView: NSTableView) -> Int {

		return self.viewModel?.attachments.value.count ?? 0
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		switch ColumnName(optionalRawValue: tableColumn?.identifier) {
		case .Preview?:
			let cell = self.tableView.make(withIdentifier: ColumnName.Preview.rawValue, owner: self) as! ImageTableCell
			if let viewModel = self.viewModel {
				cell.set(viewModel: viewModel.attachmentViewModel(for: row, column: .Preview))
			}
			return cell
		case .Name?:
			let cell = self.tableView.make(withIdentifier: ColumnName.Name.rawValue, owner: self) as! LabelTableCell
			if let viewModel = self.viewModel {
				cell.set(viewModel: viewModel.attachmentViewModel(for: row, column: .Name))
			}
			return cell
		case .Task?:
			let cell = self.tableView.make(withIdentifier: ColumnName.Task.rawValue, owner: self) as! LabelTableCell
			if let viewModel = self.viewModel {
				cell.set(viewModel: viewModel.attachmentViewModel(for: row, column: .Task))
			}
			return cell
		default:
			return nil
		}
	}

	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {

		self.viewModel?.userWantsSetSetSortDescriptors(tableView.sortDescriptors)
	}

	func tableViewSelectionDidChange(_ notification: Notification) {

		self.okButton.isEnabled = self.tableView.selectedRowIndexes.count > 0
	}
	
}
