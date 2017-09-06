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

extension NSScrollView {

	func tr_sizeThatFits(contentSize: NSSize, controlSize: NSControlSize) -> NSSize{

		let hScrollerClass: AnyClass? = {
			if let scroller = self.horizontalScroller {
				return type(of: scroller)
			} else {
				return nil
			}
		}()
		let vScrollerClass: AnyClass? = {
			if let scroller = self.verticalScroller {
				return type(of: scroller)
			} else {
				return nil
			}
		}()

		return NSScrollView.frameSize(forContentSize: contentSize, horizontalScrollerClass: hScrollerClass, verticalScrollerClass: vScrollerClass, borderType: self.borderType, controlSize: controlSize, scrollerStyle: self.scrollerStyle)
	}
}

class TaskDetailViewController: NSViewController, MVVMView {

	@IBOutlet var nameLabel: NSTextField!
	@IBOutlet var descriptionField: NSTextView!
	@IBOutlet var subtasksEmbeddingView: NSView!
	@IBOutlet var labelsEmbeddingView: NSView!
	@IBOutlet var attachmentsEmbeddingView: NSView!
	@IBOutlet var deleteButton: NSButton!

	
	@IBOutlet var descriptionHeightContraint: NSLayoutConstraint!
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

	func adjustDescriptionContainerHeight() {

		if let scrollView = self.descriptionField.enclosingScrollView {

			let kMinTextHeight: CGFloat = 40
			let kMaxTextHeight: CGFloat = 250

			guard let textContainer = self.descriptionField.textContainer, let layoutManager = textContainer.layoutManager else {
				return
			}
			let contentSize = layoutManager.usedRect(for: textContainer).size
			let scrollViewSize = scrollView.tr_sizeThatFits(contentSize: contentSize, controlSize: .regular)
			self.descriptionHeightContraint.constant = min(max(scrollViewSize.height, kMinTextHeight), kMaxTextHeight)
		}
	}

	func connectVM() {

		self.viewModel!.name.map({$0 ?? ""}).bind(to: self.nameLabel.reactive.stringValue)
		self.nameLabel.reactive.textDidEndEditing.observeNext { [weak self] (textField, flag) in

			self?.viewModel?.userWantsChangeName(name: textField.stringValue)
			self?.view.window?.makeFirstResponder(self?.view)
		}.dispose(in: bag)

		self.viewModel!.descriptionText.observeNext { [weak self] (attrString) in


			self?.descriptionField.insertText(attrString, replacementRange: NSMakeRange(0, self?.descriptionField.textStorage?.length ?? 0))
			self?.adjustDescriptionContainerHeight()

			}.dispose(in: bag)

		self.viewModel?.taskDeleteConfirmation.observeNext { [weak self] info in

			guard let info = info, let window = (self?.view.window?.parent ?? self?.view.window) else { return }

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

			self?.adjustDescriptionContainerHeight()
		}.dispose(in: bag)

		NotificationCenter.default.reactive.notification(name: Notification.Name.NSTextDidEndEditing, object:self.descriptionField).observeNext { [weak self] notification in

			if let mySelf = self {
				mySelf.viewModel?.userWantsChangeDescriptionText(attributedString: mySelf.descriptionField.attributedString())
			}
		}.dispose(in: bag)

		self.viewModel?.dismiss.filter({ doDismiss in

			return doDismiss
		}).bind(to: self) { me, dismiss in

			me.presenting?.dismissViewController(me)
		}

		let subtasksController = SubtasksViewController()
		subtasksController.set(viewModel: self.viewModel!.subtasksViewModel())
		self.subtasksController = subtasksController

		let labelsController = LabelsViewController()
		labelsController.set(viewModel: self.viewModel!.labelsViewModel())
		self.labelsController = labelsController

		let attachmentsController = AttachmentsViewController()
		attachmentsController.set(viewModel: self.viewModel!.attachmentsViewModel())
		self.attachmentsController = attachmentsController

		self.nameLabel.nextKeyView = self.descriptionField
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		let style = NSMutableParagraphStyle()
		style.alignment = .center
		let attrs = [
			NSFontAttributeName : NSFont.boldSystemFont(ofSize: 13.0),
			NSForegroundColorAttributeName: #colorLiteral(red: 0.8859125972, green: 0.1864079535, blue: 0.2725405097, alpha: 1),
			NSParagraphStyleAttributeName: style
			] as [String : Any]
		let string = NSMutableAttributedString(string:
			NSLocalizedString("Delete Task", comment: "Delete Task Button"),
		                                       attributes:attrs)
		self.deleteButton.attributedTitle = string
	}

	override func viewDidAppear() {

		if self.viewModel?.name.value?.isEmpty ?? true {

			self.view.window?.makeFirstResponder(self.nameLabel)
		}
	}
	override func viewWillDisappear() {
		super.viewWillDisappear()

		// This will cause text views being edited to send NSTextDidEndEditing notification:
		self.view.window?.makeFirstResponder(self.view)
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

	var labelsController: LabelsViewController? {
		willSet {
			guard let current = self.labelsController else { return }
			current.removeFromParentViewController()
			current.view.removeFromSuperview()
		} didSet {
			guard let current = self.labelsController else { return }
			current.view.translatesAutoresizingMaskIntoConstraints = false
			self.labelsEmbeddingView.addSubview(current.view)
			self.labelsEmbeddingView.addConstraints(NSLayoutConstraint.tr_fit(current.view))
		}
	}

	var attachmentsController: AttachmentsViewController? {
		willSet {
			guard let current = self.attachmentsController else { return }
			current.removeFromParentViewController()
			current.view.removeFromSuperview()
		} didSet {
			guard let current = self.attachmentsController else { return }
			current.view.translatesAutoresizingMaskIntoConstraints = false
			self.attachmentsEmbeddingView.addSubview(current.view)
			self.attachmentsEmbeddingView.addConstraints(NSLayoutConstraint.tr_fit(current.view))
		}
	}


	@IBAction func deleteTask(_ sender: Any) {
		self.viewModel?.userRequestsTaskDeletion()
	}
	
	@IBAction func startPomodoroSession(_ sender: Any) {
		self.view.window?.makeFirstResponder(self.nextResponder)
		NSApp.sendAction(#selector(FruokDocument.startPomodoroSession(_:)), to: nil, from: self)
	}
}
