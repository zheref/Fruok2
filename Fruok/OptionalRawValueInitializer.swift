//
//  OptionalRawValueInitializer.swift
//  Fruok
//
//  Created by Matthias Keiser on 08.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

protocol OptionalRawValueRepresentable: RawRepresentable {

	init?(optionalRawValue: Self.RawValue?)
}

extension OptionalRawValueRepresentable {

	init?(optionalRawValue: Self.RawValue?) {

		guard let rawValue = optionalRawValue else {
			return nil
		}

		self.init(rawValue: rawValue)
	}
}
