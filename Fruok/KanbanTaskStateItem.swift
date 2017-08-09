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

	typealias VIEWMODEL = KanbanTaskStateItemViewModel
	private(set) var viewModel: KanbanTaskStateItemViewModel?
	func set(viewModel: KanbanTaskStateItemViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
		self.view.layer?.backgroundColor = NSColor.red.cgColor
    }

	func connectVM() {

		self.viewModel?.name.map{
			return $0 ?? ""
		}.bind(to: self.nameLabel)
	}

	@IBAction func menuAction(_ sender: Any) {

		self.itemMenu.popUp(positioning: nil, at: .zero, in: sender as? NSView)
	}

	@IBAction func deleteTaskState(_ sender: Any) {

		NSApp.sendAction(#selector(KanbanViewController.deleteTask(_:)), to: nil, from: self)
	}

}
