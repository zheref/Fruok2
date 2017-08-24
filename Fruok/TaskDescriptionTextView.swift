//
//  TaskDescriptionTextView.swift
//  Fruok
//
//  Created by Matthias Keiser on 24.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class TaskDescriptionTextView: NSTextView {

	var placeHolderString: NSAttributedString = NSAttributedString(string:
		NSLocalizedString("Task Description...", comment: "Task Description Placeholder")
		, attributes: [
			NSFontAttributeName: NSFont.boldSystemFont(ofSize: 20),
			NSForegroundColorAttributeName : NSColor.lightGray]
	)

	let borderWidth: CGFloat = 10

	override func becomeFirstResponder() -> Bool {
		self.needsDisplay = true
		self.enclosingScrollView?.borderType = .bezelBorder
		return super.becomeFirstResponder()
	}
	override func resignFirstResponder() -> Bool {
		self.needsDisplay = true
		self.enclosingScrollView?.borderType = .noBorder
		return super.resignFirstResponder()
	}
	override func draw(_ rect: NSRect) {
		super.draw(rect)

		if (self.string! == "" && self.window?.firstResponder != self) {
			self.placeHolderString.draw(at: NSMakePoint(0, 0))
		}
	}

}
