//
//  LabelAddItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 24.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class LabelAddItem: NSCollectionViewItem {

	@IBAction func addLabel(_ sender: Any) {
		self.view.window?.makeFirstResponder(self.nextResponder)
		NSApp.sendAction(#selector(addLabel(_:)), to: nil, from: self)
	}

}
