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
	@IBOutlet weak var tasksContainerView: NSView!

	typealias VIEWMODEL = KanbanTaskStateItemViewModel
	private(set) var viewModel: KanbanTaskStateItemViewModel?
	func set(viewModel: KanbanTaskStateItemViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	var tasksCollectionView: TasksCollectionViewController? {
		willSet {
			if let controller = self.tasksCollectionView {
				controller.removeFromParentViewController()
				self.tasksCollectionView?.view.removeFromSuperview()
			}
		} didSet {
			if let controller = self.tasksCollectionView {
				self.addChildViewController(controller)
				controller.view.translatesAutoresizingMaskIntoConstraints = false
				self.tasksContainerView.tr_addFillingSubview(controller.view)
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.nameEntryField.delegate = self
        self.view.wantsLayer = true
		//self.view.layer?.backgroundColor = NSColor.red.cgColor
		self.view.layer?.cornerRadius = 8.0
		self.view.layer?.borderColor = NSColor.lightGray.cgColor
		self.view.layer?.borderWidth = 2.0
		self.tasksCollectionView = TasksCollectionViewController.create()
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

		self.tasksCollectionView?.set(viewModel: self.viewModel!.tasksCollectionViewModel())
	}

	@IBAction func menuAction(_ sender: Any) {

		self.itemMenu.popUp(positioning: nil, at: .zero, in: sender as? NSView)
	}

	@IBAction func deleteTaskState(_ sender: Any) {

		NSApp.sendAction(#selector(KanbanViewController.deleteTask(_:)), to: nil, from: self)
	}
	@IBAction func editTaskState(_ sender: Any) {

		self.viewModel?.editable.value = true
	}

	@IBAction func addTaskAction(_ sender: Any) {

		self.viewModel?.userWantsAddTask()
	}
}

extension KanbanTaskStateItem: NSTextFieldDelegate {

	override func controlTextDidEndEditing(_ obj: Notification) {

		self.viewModel?.userDidChangeName(to: self.nameEntryField.stringValue)
	}
}
