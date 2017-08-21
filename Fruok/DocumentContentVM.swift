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

		case project
		case kanban
		case statistics
		case billing
	}

	private(set) var currentChildView: Observable<ChildView?> = Observable(.project)

	func changeCurrentChildView(to childView: ChildView?) {

		if let childView = childView {

			self.currentChildView.value = childView
		}
	}

	func viewModelForProjectMetadata() -> ProjectMetadataViewModel? {

		guard let project = self.document.project else { return nil }
		return ProjectMetadataViewModel(with: project)
	}

	func viewModelForKanBan() -> KanbanViewModel? {

		guard let project = self.document.project else { return nil }
		return KanbanViewModel(with: project)
	}
}
