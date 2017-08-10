//
//  KanbanTaskItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class KanbanTaskItem: NSCollectionViewItem, MVVMView {

	typealias VIEWMODEL = KanbanTaskItemViewModel
	private(set) var viewModel: KanbanTaskItemViewModel?
	func set(viewModel: KanbanTaskItemViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	@IBOutlet weak var nameLabel: NSTextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.layer?.cornerRadius = 10
		self.view.layer?.borderColor = NSColor.lightGray.cgColor
		self.view.layer?.borderWidth = 2
		self.connectVMIfReady()
    }

	func connectVM() {

	}
}
