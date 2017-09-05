//
//  TableCellsViewModels.swift
//  Fruok
//
//  Created by Matthias Keiser on 04.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

struct ImageTableCellViewModel: MVVMViewModel {

	typealias MODEL = Optional<URL>

	let imageURL = Property<URL?>(nil)

	init(with imageURL: URL?) {
		self.imageURL.value = imageURL
	}
}

struct LabelTableCellViewModel: MVVMViewModel {

	typealias MODEL = Optional<String>

	let string = Property<String?>(nil)

	init(with string: String?) {
		self.string.value = string
	}
}
