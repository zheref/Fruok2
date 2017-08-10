//
//  DocumentWindowController.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class DocumentWindowController: NSWindowController {

	func adjustFirstResponder() {

		let docView = (self.contentViewController as? DocumentContentViewController)?.currentChildViewController?.view
		self.window?.makeFirstResponder(docView)
	}
}

class MainWindow: NSWindow {

	var isRecursiveMakeFirstResponder = false

	override func makeFirstResponder(_ responder: NSResponder?) -> Bool {

		let returnValue = super.makeFirstResponder(responder)

		if !self.isRecursiveMakeFirstResponder {
			if responder != nil ? (responder! === self) : true {

				self.isRecursiveMakeFirstResponder = true

				if let controller = self.windowController as? DocumentWindowController {
					controller.adjustFirstResponder()
				}
			}
		}

		self.isRecursiveMakeFirstResponder = false

		return returnValue
	}
}

