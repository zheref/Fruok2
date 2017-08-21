//
//  LabelEditingCell.swift
//  Fruok
//
//  Created by Matthias Keiser on 19.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

class LabelEditingCell: NSCollectionViewItem, MVVMView {

	@IBOutlet weak var colorWell: NSColorWell!
	//@IBOutlet weak var nameTextField: NSTextField!

	@IBOutlet weak var labelComboBox: NSComboBox!
	typealias VIEWMODEL = LabelEditingItemViewModel
	private(set) var viewModel: LabelEditingItemViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
	func set(viewModel: LabelEditingItemViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	private let reuseBag = DisposeBag()

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.layer?.backgroundColor = NSColor.gray.cgColor

		self.connectVMIfReady()
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		self.viewModel = nil
		self.labelComboBox.stringValue = ""
	}

	func connectVM() {

		self.viewModel?.labelColor.bind(to: self, context: .immediateOnMain, setter: { (me, colorValues) in

			me.colorWell.color = NSColor(withRGBAValues: colorValues)
		}).dispose(in: reuseBag)

		self.viewModel?.currentEditingSuggestions.bind(to: self, context: .immediateOnMain, setter: { [weak self] _ in

			self?.labelComboBox.reloadData()
		})
	}

	override func viewDidAppear() {
		super.viewDidAppear()
		self.view.window?.makeFirstResponder(self.labelComboBox)
	}

	@IBAction func textFieldAction(_ sender: Any) {

		self.view.window?.makeFirstResponder(self.view)
		NSApp.sendAction(#selector(LabelsViewController.commitEditLabel(_:)), to: nil, from: self)
	}

	@IBAction override func cancelOperation(_ sender: Any?) {

		self.view.window?.makeFirstResponder(self.view)
		NSApp.sendAction(#selector(LabelsViewController.cancelEditLabel(_:)), to: nil, from: self)
	}

	@IBAction func colorAction(_ sender: NSColorWell) {

		if let colorValues = sender.color.rgbaColorValues {
			self.viewModel?.labelColor.value = colorValues
		}
	}
	
}

extension LabelEditingCell: NSTextFieldDelegate {

	override func controlTextDidChange(_ obj: Notification) {

		self.viewModel?.currentEditingString.value = self.labelComboBox.stringValue
	}
}

extension LabelEditingCell: NSComboBoxDelegate {

	func comboBoxSelectionDidChange(_ notification: Notification) {

		self.viewModel?.userSelectedExistingLabel(atCurrentSuggestionsIndex: self.labelComboBox.indexOfSelectedItem)
		self.view.window?.makeFirstResponder(self.view)
		NSApp.sendAction(#selector(LabelsViewController.setExistingLabel(_:)), to: nil, from: self)

	}
}
extension LabelEditingCell: NSComboBoxDataSource {

	func numberOfItems(in comboBox: NSComboBox) -> Int {
		return self.viewModel?.currentEditingSuggestions.value.count ?? 0
	}

	func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {

		guard let (string, colorValues) = self.viewModel?.currentEditingSuggestions.value[index] else {
			return nil
		}

		return NSAttributedString(string: string, attributes: [NSBackgroundColorAttributeName: NSColor(withRGBAValues: colorValues)])
	}

}

class LabelEditingCellView: FirstResponderView {

	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)
		self.layer?.cornerRadius = min(newSize.width, newSize.height) / 2
	}
}

class LabelComboBox: NSComboBox {

	override func becomeFirstResponder() -> Bool {
		let result = super.becomeFirstResponder()

		if result {
			self.cell?.setAccessibilityExpanded(true)
		}
		return result
	}
}
