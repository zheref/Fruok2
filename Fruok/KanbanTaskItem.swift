//
//  KanbanTaskItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond

class KanbanTaskItem: NSCollectionViewItem, MVVMView {

	typealias VIEWMODEL = KanbanTaskItemViewModel
	private(set) var viewModel: KanbanTaskItemViewModel?
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

	func connectVM() {

		self.viewModel!.showTaskDetails.observeNext { show in

			if show {

				self.doShowTaskDetails()
			}
		}.dispose(in: bag)

		self.nameLabel.reactive.editingString.bidirectionalMap(to: {$0}, from: {$0 ?? ""}).bidirectionalBind(to: self.viewModel!.taskName)
//		self.viewModel!.taskName.bidirectionalBind(to: self.nameLabel.reactive.editingString)
		self.viewModel!.taskDescription.map{$0 ?? ""}.bind(to: self.descriptionLabel)
	}
	@IBAction func showTaskDetailAction(_ sender: Any) {

		self.viewModel?.userRequestedTaskDetails()
	}

	lazy var popover: NSPopover = {
		let popover = NSPopover()
		popover.behavior = .transient
		return popover
	}()
	var detailViewController: TaskDetailViewController?

	func doShowTaskDetails() {

		if self.popover.isShown {
			return
		}

		let controller = TaskDetailViewController()
		controller.set(viewModel: self.viewModel!.viewModelForTaskDetail())
		self.detailViewController = controller

		self.popover.contentViewController = controller

		self.popover.show(relativeTo: self.view.bounds, of: self.view, preferredEdge: NSRectEdge.maxX)
	}
}
