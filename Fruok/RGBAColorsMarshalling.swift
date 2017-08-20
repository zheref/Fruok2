//
//  LabelColors.swift
//  Fruok
//
//  Created by Matthias Keiser on 20.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

struct RGBAColorValues {

	let r: Double
	let g: Double
	let b: Double
	let a: Double
}

extension RGBAColorValues {

	static let defaultLabelColor = RGBAColorValues(r:1.0, g: 1.0, b: 0.0, a: 1.0)
}
