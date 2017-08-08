//
//  DocumentContentVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import Bond

class DocumentContentViewModel {

	public enum ChildView: Int, OptionalRawValueRepresentable {

		case kanban
		case statistics
		case billing
	}

	private(set) var currentChildView: Observable<ChildView?> = Observable(.kanban)

	func changeCurrentChildView(to childView: ChildView?) {

		if let childView = childView {

			self.currentChildView.value = childView
		}
	}
}
