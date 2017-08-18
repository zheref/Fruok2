//
//  TasksCollectionLayout.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class TasksCollectionLayout: VerticalFittingCollectionLayout {

	convenience init() {

		self.init(
			withItemIdension: 130.0,
			interItemMargin: 10.0,
			leadingEdgeMargin: 10.0,
			trailingEdgeMargin: 10.0)
	}
}

