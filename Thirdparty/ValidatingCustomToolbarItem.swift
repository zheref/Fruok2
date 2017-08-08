//
//  ValidatingCustomToolbarItem.swift
//  fseventstool
//
//  Created by Matthias Keiser on 22.09.16.
//  Copyright © 2016 Tristan Inc. All rights reserved.
//

import Foundation

class ValidatingCustomToolbarItem: NSToolbarItem {

	 override func validate() {

		guard let action = self.action else {
			return
		}

		guard let target = self.target ?? NSApp.target(forAction: action, to: nil, from: self) as AnyObject? else {
			return
		}

		if target.responds(to: #selector(validateToolbarItem)) {

			self.isEnabled = target.validateToolbarItem(self)
		} else {
			self.isEnabled = true
		}
	}
}
