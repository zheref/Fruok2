//
//  ViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class DocumentContentViewController: NSViewController {

	@IBOutlet var containerView: NSView!

	let viewModel = DocumentContentViewModel()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

}

