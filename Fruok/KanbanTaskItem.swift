//
//  KanbanTaskItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

class KanbanTaskItem: NSCollectionViewItem, MVVMView {

	typealias VIEWMODEL = KanbanTaskItemViewModel
	private(set) var viewModel: KanbanTaskItemViewModel?{
		willSet {
			self.reuseBag.dispose()
		}
	}
	func set(viewModel: KanbanTaskItemViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	@IBOutlet weak var nameLabel: NSTextField!
	@IBOutlet weak var descriptionLabel: NSTextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.layer?.cornerRadius = 10
		self.view.layer?.borderColor = NSColor.lightGray.cgColor
		self.view.layer?.borderWidth = 2
		self.connectVMIfReady()
    }

	private let reuseBag = DisposeBag()

	override func prepareForReuse() {
		super.prepareForReuse()
		self.viewModel = nil
	}

	func connectVM() {

		self.viewModel!.showTaskDetails.observeNext { show in

			if show {

				self.doShowTaskDetails()
			}
		}.dispose(in: reuseBag)

		self.viewModel!.taskName.map({$0 ?? ""}).bind(to: self.nameLabel.reactive.editingString).dispose(in: reuseBag)
		self.viewModel!.taskDescription.map{$0 ?? ""}.bind(to: self.descriptionLabel).dispose(in: reuseBag)
	}
	@IBAction func showTaskDetailAction(_ sender: Any) {

		self.view.window?.makeFirstResponder(self.view)
		self.viewModel?.userRequestedTaskDetails()
	}

	func doShowTaskDetails() {

		NSApp.sendAction(#selector(KanbanViewController.showTaskDetails(_:)), to: nil, from: self)
	}
}
