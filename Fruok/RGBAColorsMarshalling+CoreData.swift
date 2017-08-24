//
//  LabelColorsMarshalling+CoreData.swift
//  Fruok
//
//  Created by Matthias Keiser on 20.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

extension RGBAColor {

	var rgbaColorValues: RGBAColorValues {
		get {
			return RGBAColorValues(r: self.r, g: self.g, b: self.b, a: self.a)
		} set {

			self.managedObjectContext?.undoGroupWithOperations({ context in

				self.r = newValue.r
				self.g = newValue.g
				self.b = newValue.b
				self.a = newValue.a
			})
		}
	}
}
