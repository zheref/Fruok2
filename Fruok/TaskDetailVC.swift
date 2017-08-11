//
//  TaskDetailVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit
import Bond

public extension ReactiveExtensions where Base: NSTextView {

	public var tr_attributedString: DynamicSubject<NSAttributedString?> {
		let notificationName = NSNotification.Name.NSTextDidChange
		return dynamicSubject(
			signal: NotificationCenter.default.reactive.notification(name: notificationName, object: base).eraseType(),
			get: { $0.textStorage },
			set: { $0.textStorage?.setAttributedString($1 ?? NSAttributedString()) }
		)
	}
}

class TaskDetailViewController: NSViewController, MVVMView {

	@IBOutlet var nameLabel: NSTextField!
	@IBOutlet var descriptionField: NSTextView!

	typealias VIEWMODEL = TaskDetailViewModel
	private(set) var viewModel: TaskDetailViewModel?
	internal func set(viewModel: TaskDetailViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {

		self.init(nibName: "TaskDetailVC", bundle: nil)!
	}
    override func viewDidLoad() {
        super.viewDidLoad()
		self.connectVMIfReady()
    }

	var suppressTextChange = false // HACK

	func connectVM() {

		self.viewModel!.name.map({$0 ?? ""}).bind(to: self.nameLabel.reactive.stringValue)
		self.nameLabel.reactive.textDidEndEditing.observeNext { (textField, flag) in

			self.viewModel?.name.value = textField.stringValue
		}.dispose(in: bag)

		self.viewModel!.descriptionText.map({$0 ?? NSAttributedString()}).observeNext { (attrString) in

			if self.suppressTextChange {
				return
			}
			self.descriptionField.insertText(attrString, replacementRange: NSMakeRange(0, self.descriptionField.textStorage?.length ?? 0))
		}.dispose(in: bag)

		NotificationCenter.default.reactive.notification(name: Notification.Name.NSTextDidChange, object:self.descriptionField).observeNext { [weak self] notification in

			if let mySelf = self {
				mySelf.suppressTextChange = true
				mySelf.viewModel!.descriptionText.value = mySelf.descriptionField.attributedString()
				mySelf.suppressTextChange = false
			}
		}.dispose(in: bag)

		self.viewModel?.dismiss.filter({ doDismiss in

			return doDismiss
		}).bind(to: self) { me, dismiss in

			me.dismiss(nil)
		}
	}

	@IBAction func deleteTask(_ sender: Any) {
		self.viewModel?.userRequestsTaskDeletion()
	}
	
}
