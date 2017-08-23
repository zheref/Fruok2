//
//  AttachmentCell.swift
//  Fruok
//
//  Created by Matthias Keiser on 22.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit
import Bond

class AttachmentImageCell: NSTableCellView, MVVMView {

	typealias VIEWMODEL = AttachmentCellViewModel
	private(set) var viewModel: AttachmentCellViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
	internal func set(viewModel: AttachmentCellViewModel) {

		self.reuseBag.dispose()
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	private let reuseBag = DisposeBag()

	func connectVM() {

		self.viewModel?.attachmentURL
			.flatMap { $0 }
			.map {
				NSWorkspace.shared().icon(forFile: $0.path)
//				if let path = $0?.path {
//					NSWorkspace.shared().icon(forFile: path)
//				} else {
//					return nil
//				}
			}
			.observeNext {[weak self] image in

//				if let image = image {
					self?.imageView?.image = image
//				}
		}.dispose(in: reuseBag)
	}
}

class AttachmentFilenameCell: NSTableCellView, MVVMView {

	typealias VIEWMODEL = AttachmentCellViewModel
	private(set) var viewModel: AttachmentCellViewModel? {
		willSet {
			self.reuseBag.dispose()
		}
	}
	internal func set(viewModel: AttachmentCellViewModel) {

		self.reuseBag.dispose()
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	private let reuseBag = DisposeBag()

	func connectVM() {

		self.viewModel?.filename.observeNext(with: { filename in
			self.textField?.stringValue = filename
		}).dispose(in: reuseBag)

	}
}
