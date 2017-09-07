//
//  AttachmentOverviewViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 04.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

class AttachmentOverviewController: NSViewController, MVVMView {


	@IBOutlet var tableView: NSTableView!

	typealias VIEWMODEL = AttachmentOverviewViewModel
	private(set) var viewModel: AttachmentOverviewViewModel?
	internal func set(viewModel: AttachmentOverviewViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}



	convenience init() {
		self.init(nibName:"AttachmentOverviewVC", bundle: nil)!
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.attachments.observeNext(with: { [weak self] attachments in

			self?.tableView.reloadData()
		}).dispose(in: bag)

		self.viewModel?.attachmentsToOpen.observeNext(with: { urls in

			for url in urls {
				NSWorkspace.shared().open(url)
			}

		}).dispose(in: bag)

		self.viewModel?.attchmentDeleteConfirmation.observeNext(with: { [weak self] info in

			guard let info = info, let window = (self?.view.window?.parent ?? self?.view.window) else { return }

			let alert = NSAlert()
			alert.alertStyle = .warning
			alert.messageText = info.question
			alert.informativeText = info.detailString
			alert.addButton(withTitle: NSLocalizedString("Delete", comment: "Confirm task deletion button"))
			alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel task deletion button"))

			alert.beginSheetModal(for: window, completionHandler: { response in

				if response == NSAlertFirstButtonReturn {
					info.callback()
				}
			})
		}).dispose(in: bag)
	}

	@IBAction func open(_ sender: Any) {

		self.viewModel?.userWantsOpenAttachmentsAt(indexes: self.tableView.selectedRowIndexes)
	}

	@IBAction func delete(_ sender: Any?) {

		if self.tableView.clickedRow >= 0 {
			let indexes = IndexSet(integer: self.tableView.clickedRow)
			self.viewModel?.userWantsDeleteAttachments(at: indexes)
		}
	}
}

extension AttachmentOverviewController: NSTableViewDataSource, NSTableViewDelegate {

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
	
	
}
