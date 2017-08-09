//
//  KVVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import AppKit

protocol MVVMViewModel {

	associatedtype MODEL
	init(with model: MODEL)
}

protocol MVVMView {

	associatedtype VIEWMODEL: MVVMViewModel
	func set(viewModel: VIEWMODEL)
	var viewModel: VIEWMODEL? {get}
	func connectVMIfReady()
	func connectVM()
}

extension MVVMView where Self: NSViewController {

	func connectVMIfReady() {

		if self.viewModel != nil && self.isViewLoaded {
			self.connectVM()
		}
	}
}

extension MVVMView where Self: NSView {

	func connectVMIfReady() {

		if self.viewModel != nil {
			self.connectVM()
		}
	}
}
