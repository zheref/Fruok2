//
//  AttachmentCellVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 22.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

struct AttachmentCellViewModel: MVVMViewModel {

	typealias MODEL = Optional<URL>
	let attachmentURL: Property<URL?>
	let filename = Property<String>("")

	init(with url: URL?, filename: String) {
		self.init(with: url)
		self.filename.value = filename
	}
	init(with url: URL?) {
		self.attachmentURL = Property(url)
	}
}
