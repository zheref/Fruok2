//
//  RGBAColorsMarshalling+NSColor.swift
//  Fruok
//
//  Created by Matthias Keiser on 20.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

extension NSColor {

	var rgbaColorValues: RGBAColorValues? {
		get {

			if let converted = self.usingColorSpace(NSColorSpace.sRGB) {

				return RGBAColorValues(r: Double(converted.redComponent),
				                       g: Double(converted.greenComponent),
				                       b: Double(converted.blueComponent),
				                       a: Double(converted.alphaComponent))
			}
			return nil
		}
	}

	convenience init(withRGBAValues values: RGBAColorValues) {

		self.init(srgbRed: CGFloat(values.r), green: CGFloat(values.g), blue: CGFloat(values.b), alpha: CGFloat(values.a))
	}
}
