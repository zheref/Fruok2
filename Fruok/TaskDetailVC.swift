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
	@IBOutlet var subtasksEmbeddingView: NSView!

	typealias VIEWMODEL = TaskDetailViewModel
	private(set) var viewModel: TaskDetailViewModel?
	internal func set(viewModel: TaskDetailViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {

		self.init(nibName: "TaskDetailVC", bundle: nil)!
	}
	deinit {
		NSLog("TaskDetailViewController deinit")
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

		self.viewModel!.descriptionText.map({$0 ?? NSAttributedString()}).observeNext { [weak self] (attrString) in

			guard let strongSelf = self else {return}

			if strongSelf.suppressTextChange {
				return
			}
			strongSelf.descriptionField.insertText(attrString, replacementRange: NSMakeRange(0, strongSelf.descriptionField.textStorage?.length ?? 0))
		}.dispose(in: bag)

		self.viewModel?.taskDeleteConfirmation.observeNext { [weak self] info in

			guard let info = info, let window = self?.view.window?.parent else { return }

			let alert = NSAlert()
			alert.alertStyle = .informational
			alert.messageText = info.question
			alert.addButton(withTitle: NSLocalizedString("Delete", comment: "Confirm task deletion button"))
			alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel task deletion button"))

			alert.beginSheetModal(for: window, completionHandler: { response in

				if response == NSAlertFirstButtonReturn {
					info.callback()
				}
			})
			
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

		let subtasksController = SubtasksViewController()
		subtasksController.set(viewModel: self.viewModel!.subtasksViewModel())
		self.subtasksController = subtasksController
	}

	var subtasksController: SubtasksViewController? {
		willSet {
			guard let current = self.subtasksController else { return }
			current.removeFromParentViewController()
			current.view.removeFromSuperview()
		} didSet {
			guard let current = self.subtasksController else { return }
			current.view.translatesAutoresizingMaskIntoConstraints = false
			self.subtasksEmbeddingView.addSubview(current.view)
			self.subtasksEmbeddingView.addConstraints(NSLayoutConstraint.tr_fit(current.view))
		}
	}

	@IBAction func deleteTask(_ sender: Any) {
		self.viewModel?.userRequestsTaskDeletion()
	}
	
}
