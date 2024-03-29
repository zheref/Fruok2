//
//  TaskStateCollectionItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 09.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

class KanbanTaskStateItem: NSCollectionViewItem, MVVMView {

	@IBOutlet var nameLabel: NSTextField!
	@IBOutlet var itemMenu: NSMenu!
	@IBOutlet weak var nameEntryField: NSTextField!
	@IBOutlet weak var tasksContainerView: NSView!

	typealias VIEWMODEL = KanbanTaskStateItemViewModel
	private(set) var viewModel: KanbanTaskStateItemViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
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
		self.view.layer?.backgroundColor = NSColor(calibratedWhite: 0.9, alpha: 1.0).cgColor
		self.tasksCollectionView = TasksCollectionViewController.create()
		self.connectVMIfReady()
    }

	private let reuseBag = DisposeBag()

	override func viewDidAppear() {
		super.viewDidAppear()
		if self.viewModel?.editable.value ?? false {

			// This is a bit of a hack to make the editable value signal again,
			// so that we can set the first responder
			self.viewModel?.editable.value = false
			self.viewModel?.editable.value = true
		}
	}

	func connectVM() {

		self.viewModel?.name.map{
			return $0 ?? ""
		}.bind(to: self.nameLabel).dispose(in: self.reuseBag)

		self.viewModel!.editable.observeNext(with: {editable in

			if editable {
				self.nameLabel.isHidden = true
				self.nameEntryField.isHidden = false
				self.view.window?.makeFirstResponder(self.nameEntryField)
			} else {
				self.nameLabel.isHidden = false
				self.nameEntryField.isHidden = true
			}
		}).dispose(in: self.reuseBag)

		self.tasksCollectionView?.set(viewModel: self.viewModel!.tasksCollectionViewModel())
	}

	override func prepareForReuse() {

		super.prepareForReuse()
		self.viewModel = nil
	}

	@IBAction func menuAction(_ sender: Any) {

		self.view.window?.makeFirstResponder(self.view)
		self.itemMenu.popUp(positioning: nil, at: .zero, in: sender as? NSView)
	}

	@IBAction func deleteTaskState(_ sender: Any) {

		NSApp.sendAction(#selector(KanbanViewController.deleteTaskStateAction(_:)), to: nil, from: self)
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
