//
//  TableCells.swift
//  Fruok
//
//  Created by Matthias Keiser on 04.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit
import Bond

class ImageTableCell: NSTableCellView, MVVMView {

	typealias VIEWMODEL = ImageTableCellViewModel
	private(set) var viewModel: ImageTableCellViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
	internal func set(viewModel: ImageTableCellViewModel) {

		self.reuseBag.dispose()
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	private let reuseBag = DisposeBag()

	func connectVM() {

		self.viewModel?.imageURL
			.flatMap { $0 }
			.map {
				NSWorkspace.shared().icon(forFile: $0.path)
			}
			.observeNext {[weak self] image in

				self?.imageView?.image = image
			}.dispose(in: reuseBag)
	}
}

class LabelTableCell: NSTableCellView, MVVMView {

	typealias VIEWMODEL = LabelTableCellViewModel
	private(set) var viewModel: LabelTableCellViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
	internal func set(viewModel: LabelTableCellViewModel) {

		self.reuseBag.dispose()
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	private let reuseBag = DisposeBag()

	func connectVM() {

		self.viewModel?.string.observeNext(with: { filename in
			self.textField?.stringValue = filename ?? ""
		}).dispose(in: reuseBag)
		
	}
}
