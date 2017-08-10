//
//  TaskStateCollectionItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 09.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class KanbanTaskStateItem: NSCollectionViewItem, MVVMView {

	@IBOutlet var nameLabel: NSTextField!
	@IBOutlet var itemMenu: NSMenu!
	@IBOutlet weak var nameEntryField: NSTextField!

	typealias VIEWMODEL = KanbanTaskStateItemViewModel
	private(set) var viewModel: KanbanTaskStateItemViewModel?
	func set(viewModel: KanbanTaskStateItemViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.nameEntryField.delegate = self
        self.view.wantsLayer = true
		self.view.layer?.backgroundColor = NSColor.red.cgColor
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.name.map{
			return $0 ?? ""
		}.bind(to: self.nameLabel)

		self.viewModel!.editable.observeNext(with: {editable in

			if editable {
				self.nameLabel.isHidden = true
				self.nameEntryField.isHidden = false
				self.view.window?.makeFirstResponder(self.nameEntryField)
			} else {
				self.nameLabel.isHidden = false
				self.nameEntryField.isHidden = true
			}
		}).dispose(in: bag)
	}

	@IBAction func menuAction(_ sender: Any) {

		self.itemMenu.popUp(positioning: nil, at: .zero, in: sender as? NSView)
	}

	@IBAction func deleteTaskState(_ sender: Any) {

		NSApp.sendAction(#selector(KanbanViewController.deleteTask(_:)), to: nil, from: self)
	}

}

extension KanbanTaskStateItem: NSTextFieldDelegate {

//	func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
//		self.viewModel?.userDidChangeName(to: self.nameLabel.stringValue)
//		return true
//	}

	override func controlTextDidEndEditing(_ obj: Notification) {

		self.viewModel?.userDidChangeName(to: self.nameEntryField.stringValue)
	}
}
