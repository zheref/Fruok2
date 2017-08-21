//
//  LabelItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 18.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

class LabelItem: NSCollectionViewItem, MVVMView {

	@IBOutlet weak var nameField: NSTextField!
	typealias VIEWMODEL = LabelItemViewModel
	private(set) var viewModel: LabelItemViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
	func set(viewModel: LabelItemViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.layer?.cornerRadius = 10
		//self.view.layer?.borderWidth = 2
		self.connectVMIfReady()
    }

	private let reuseBag = DisposeBag()

	override func prepareForReuse() {
		super.prepareForReuse()
		self.viewModel = nil
	}

	func connectVM() {

		self.viewModel?.name.bind(to: self, context: .immediateOnMain, setter: { (me, name) in
			me.nameField.stringValue = name
		}).dispose(in: reuseBag)
		
		self.viewModel?.color.bind(to: self, context: .immediateOnMain, setter: { (me, color) in
			let nsColor = NSColor(withRGBAValues: color)
			me.view.layer?.backgroundColor = nsColor.cgColor
			//me.view.layer?.borderColor = nsColor.cgColor
			//me.nameField.textColor = nsColor
		}).dispose(in: reuseBag)
	}

	let suggestionMenu = NSMenu()

	@IBAction func edit(_ sender: Any?) {

		NSApp.sendAction(#selector(LabelsViewController.editLabel(_:)), to: nil, from: self)
	}

	@IBAction func delete(_ sender: Any?) {

		NSApp.sendAction(#selector(LabelsViewController.deleteLabel(_:)), to: nil, from: self)
	}
}

class LabelItemView: FirstResponderView {

	override func hitTest(_ point: NSPoint) -> NSView? {

		if self.frame.contains(point) { return self }
		return super.hitTest(point)
	}
}

//extension LabelItem: NSTextFieldDelegate {
//
//	func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
//
//		return ["aaaaa", "bbbbb"]
//	}
//
//}
//extension LabelItem: NSComboBoxDataSource {
//
//	func numberOfItems(in comboBox: NSComboBox) -> Int {
//
//		return self.viewModel?.currentEditingSuggestions.value.count ?? 0
//	}
//
//	func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
//
//		guard let tuple = self.viewModel?.currentEditingSuggestions.value[index] else { return nil }
//
//		return NSAttributedString(string: tuple.name, attributes: [NSForegroundColorAttributeName: /*tuple.color*/NSColor.green])
//	}
//}
//
//extension LabelItem: NSComboBoxDelegate {
//
//	func comboBoxSelectionDidChange(_ notification: Notification) {
//
//		
//		self.viewModel?.name.value = self.viewModel?.currentEditingSuggestions.value[index]
//		self.nameComboBox.st
//		self.view.window?.makeFirstResponder(self.view)
//		self.viewModel?.editable.value = false
//	}
//}
