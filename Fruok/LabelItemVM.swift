//
//  LabelItemVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 18.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

class LabelItemViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Label
	@objc private let label: Label
	required init(with model: Label) {
		self.label = model
		super.init()

		self.reactive.keyPath(#keyPath(LabelItemViewModel.label.name), ofType: String.self, context: .immediateOnMain).bind(to: self.name)

		self.reactive.keyPath(#keyPath(LabelItemViewModel.label.color), ofType: Optional<LabelColor>.self, context: .immediateOnMain)
			.map{ labelColor in
				return labelColor?.rgbaColorValues ?? RGBAColorValues.defaultLabelColor
		}.bind(to: self.color)
	}

	let name = Property<String>("")
	let color = Property<RGBAColorValues>(RGBAColorValues.defaultLabelColor)
}
