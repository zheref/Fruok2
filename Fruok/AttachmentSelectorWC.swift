//
//  AttachmentSelectorWindowController.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class AttachmentSelectorWindowController: NSWindowController {

	convenience init() {
		self.init(windowNibName: "AttachmentSelectorWC")
		let controller = AttachmentSelectorViewController()
		controller.view.translatesAutoresizingMaskIntoConstraints = false
		self.contentViewController = controller
	}

	var attachmentViewController: AttachmentSelectorViewController {
		return self.contentViewController as! AttachmentSelectorViewController
	}

}
