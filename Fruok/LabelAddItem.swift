//
//  LabelAddItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 24.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class LabelAddItem: NSCollectionViewItem {

	@IBOutlet weak var addButton: NSButton!

	override func awakeFromNib() {
		super.awakeFromNib()
		let attrs = [NSFontAttributeName : NSFont.boldSystemFont(ofSize: 13.0), NSForegroundColorAttributeName: NSColor.lightGray]
		let string = NSMutableAttributedString(string:
			NSLocalizedString("Add Label...", comment: "Add label button"),
			attributes:attrs)
		self.addButton.attributedTitle = string
}
	@IBAction func addLabel(_ sender: Any) {
		self.view.window?.makeFirstResponder(self.nextResponder)
		NSApp.sendAction(#selector(addLabel(_:)), to: nil, from: self)
	}

}
