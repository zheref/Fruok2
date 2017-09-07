//
//  AttachmentsVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 22.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class AttachmentsViewController: NSViewController, MVVMView {

	@IBOutlet var tableView: NSTableView!
	typealias VIEWMODEL = AttachmentsViewModel
	private(set) var viewModel: AttachmentsViewModel?
	func set(viewModel: AttachmentsViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.doubleAction = #selector(AttachmentsViewController.openAttachment(_:))
		self.tableView.target = self
		self.tableView.register(forDraggedTypes: [kUTTypeFileURL as String])
		self.connectVMIfReady()
	}

	convenience init() {

		self.init(nibName: "AttachmentsVC", bundle: nil)!
	}
	
	func connectVM() {

		self.viewModel?.viewActions.observeNext(with: { [weak self] action in

			self?.executeCollectionViewModelAction(action)

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
//			alert.informativeText = info.detailString?
			alert.addButton(withTitle: NSLocalizedString("Remove", comment: "Confirm attachment remove button"))
			alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel attachment remove button"))

			alert.beginSheetModal(for: window, completionHandler: { response in

				if response == NSAlertFirstButtonReturn {
					info.callback()
				}
			})
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
	
	@IBAction func addFiles(_ sender: Any) {

		self.view.window?.makeFirstResponder(self.view)
		let panel = NSOpenPanel()
		panel.beginSheetModal(for: self.view.window!) { response in

			guard response == NSFileHandlingPanelOKButton else {
				return
			}

			self.viewModel?.userWantsAddAttachments(panel.urls)
		}

	}

	@IBAction func assignAttachment(_ sender: Any) {

		let sheetController = AttachmentSelectorWindowController()
		if let selectorViewModel = self.viewModel?.attachmentSelectorViewModel() {
			sheetController.attachmentViewController.set(viewModel: selectorViewModel)
		}
		
		self.view.window?.beginSheet(sheetController.window!, completionHandler: { response in

			_ = sheetController
		})
	}

	@IBAction func openAttachment(_ sender: Any?) {

		self.viewModel?.userWantsOpenAttachmentsAt(indexes: self.tableView.selectedRowIndexes)
	}

	@IBAction func delete(_ sender: Any?) {

		if self.tableView.clickedRow >= 0 {
			let indexes = IndexSet(integer: self.tableView.clickedRow)
			self.viewModel?.userWantsDeleteAttachments(at: indexes)
		}
	}
}

extension AttachmentsViewController: NSTableViewDataSource, NSTableViewDelegate {

	enum ColumnName: String, OptionalRawValueRepresentable {
		case Image
		case Name
	}

	func numberOfRows(in tableView: NSTableView) -> Int {

		return self.viewModel?.numCollectionObjects.value ?? 0
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

		switch ColumnName(optionalRawValue: tableColumn?.identifier) {
		case .Image?:
			let cell = self.tableView.make(withIdentifier: ColumnName.Image.rawValue, owner: self) as! AttachmentImageCell
			if let rowViewModel = self.viewModel?.attachmentViewModel(for: row) {
				cell.set(viewModel: rowViewModel)
			}
			return cell
		case .Name?:
			let cell = self.tableView.make(withIdentifier: ColumnName.Name.rawValue, owner: self) as! AttachmentFilenameCell
			if let rowViewModel = self.viewModel?.attachmentViewModel(for: row) {
				cell.set(viewModel: rowViewModel)
			}
			return cell
		default:
			return nil
		}
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {

		let urls = info.draggingPasteboard().pasteboardItems?
			.map { $0.propertyList(forType: kUTTypeFileURL as String) }
			.flatMap{ $0 }
			.map { NSURL(pasteboardPropertyList: $0, ofType: kUTTypeFileURL as String) as? URL }
			.flatMap{ $0 }

		if let urls = urls, urls.count > 0 {

			self.viewModel?.userWantsAddAttachments(urls, at: row)
			return true
		}

		return false
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {

		if info.draggingPasteboard().availableType(from: [kUTTypeFileURL as String]) != nil {
			if dropOperation == .on {
				tableView.setDropRow(row, dropOperation: .above)
			}
			return .copy
		}
		return []
	}
}
