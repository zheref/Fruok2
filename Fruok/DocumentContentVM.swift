//
//  DocumentContentVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import Bond

class DocumentContentViewModel: MVVMViewModel {

	typealias MODEL = FruokDocument

	required init(with document: FruokDocument) {

		self.document = document
	}

	let document: FruokDocument

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

	func prepareCurentChildViewController(_ controller: NSViewController) {

		switch self.currentChildView.value {
		case .kanban?:
			if let project = self.document.project {
				let viewModel = KanbanViewModel(with: project)
				(controller as! KanbanViewController).set(viewModel: viewModel)
			}
		default:
			break
		}
	}
}
