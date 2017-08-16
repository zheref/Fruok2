//
//  OneDirectionalScrollView.swift
//  Fruok
//
//  Created by Matthias Keiser on 15.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class NestedScrollView: NSScrollView {

	override func scrollWheel(with event: NSEvent) {
		
		self.nextResponder?.scrollWheel(with: event)
		super.scrollWheel(with: event)
	}
}
