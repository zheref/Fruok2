//
//  Document.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class Document: NSPersistentDocument {

	override init() {
	    super.init()
		// Add your subclass-specific initialization here.
	}

	override class func autosavesInPlace() -> Bool {
		return true
	}

	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
		self.addWindowController(windowController)
	}

}
