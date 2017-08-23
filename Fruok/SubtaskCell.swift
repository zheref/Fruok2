//
//  SubtaskCell.swift
//  Fruok
//
//  Created by Matthias Keiser on 16.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond
import ReactiveKit

class SubtaskCell: NSTableCellView, MVVMView {


	@IBOutlet var nameLabel: NSTextField!
	@IBOutlet var doneCheckbox: NSButton!
	@IBOutlet var nameEditingField: NSTextField!

	typealias VIEWMODEL = SubtaskViewModel
	private(set) var viewModel: SubtaskViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
	internal func set(viewModel: SubtaskViewModel) {

		self.reuseBag.dispose()
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	private let reuseBag = DisposeBag()

	func connectVM() {

		self.viewModel?.done.map{ $0 ? NSOnState : NSOffState}.bind(to: self.doneCheckbox.reactive.state)
		self.doneCheckbox.reactive.state.map{ $0 == NSOnState ? true : false }.bind(to: self.viewModel!.done)

		self.viewModel?.name.bind(to: self.nameLabel.reactive.stringValue)
		self.viewModel!.editable.observeNext(with: { [weak self] editable in

			if editable {
				self?.nameLabel.isHidden = true
				self?.nameEditingField.isHidden = false
				self?.nameEditingField.isEnabled = true
			} else {
				self?.nameLabel.isHidden = false
				self?.nameEditingField.isHidden = true
				self?.nameEditingField.isEnabled = false
			}
		}).dispose(in: reuseBag)

		self.reactive.keyPath(#keyPath(SubtaskCell.window), ofType: Optional<NSWindow>.self).bind(to: self, context: .immediateOnMain) { (me, window) in

			if (me.viewModel?.editable.value ?? false) {
				window?.makeFirstResponder(me.nameEditingField)
			}
		}
	}

	var didAwake = false
	override func awakeFromNib() {
		super.awakeFromNib()
		self.nameEditingField.target = self
		self.nameEditingField.action = #selector(SubtaskCell.nameFieldAction(_:))
		self.didAwake = true
		self.connectVMIfReady()
	}

	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		self.connectVMIfReady()
	}
	func connectVMIfReady() {

		if self.viewModel != nil && self.didAwake && self.window != nil {
			self.connectVM()
		}
	}

	@IBAction func nameFieldAction(_ sender: Any?) {

		self.viewModel?.userWantsSetSubtaskName(self.nameEditingField.stringValue)
	}
	
	@IBAction override func cancelOperation(_ sender: Any?) {

		self.nameEditingField.stringValue = self.nameLabel.stringValue
		
		var nextResponder: NSResponder? = self.nextResponder

		while nextResponder != nil {

			if nextResponder!.responds(to: #selector(cancelOperation(_:))) {
				nextResponder?.cancelOperation(sender)
				break
			}
			nextResponder = nextResponder?.nextResponder
		}
	}
}

