//
//  KanbanCollectionLayout.swift
//  Fruok
//
//  Created by Matthias Keiser on 09.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class KanbanCollectionLayout: HorizontalFittingCollectionLayout {

	convenience init() {

		self.init(
			withItemIdension: 200.0,
			interItemMargin: 10.0,
			leadingEdgeMargin: 10.0,
			trailingEdgeMargin: 10.0)
	}
}
