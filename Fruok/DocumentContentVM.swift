//
//  DocumentContentVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond

class DocumentContentViewModel: NSObject, MVVMViewModel {

	enum Action {
		case notifySessionEnded(notification: String)
		case notifyBreakEnded(notification: String)
	}

	typealias MODEL = FruokDocument

	required init(with document: FruokDocument) {

		self.document = document
		super.init()		
	}

	let document: FruokDocument

	public enum ChildView: Int, OptionalRawValueRepresentable {

		case project
		case kanban
		case attachments
		case statistics
		case billing
	}

	private(set) var currentChildView: Observable<ChildView?> = Observable(.project)
	let pomodoroVisible = Property<PomodoroViewModel?>(nil)
	let action = Property<Action?>(nil)

	func changeCurrentChildView(to childView: ChildView) {

		self.document.save(nil)
		self.currentChildView.value = childView
	}

	@objc func changeCurrentChildViewAfterAveOperationOfDocument(_ document: NSDocument, didSave: Bool, context: UnsafeMutableRawPointer) {

		if didSave {
			let rawValue = Int(bitPattern: context)
			if let view = ChildView(rawValue: Int(rawValue)) {
				self.changeCurrentChildView(to: view)
			}
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

	func viewModelForAttachments() -> AttachmentOverviewViewModel? {

		guard let project = self.document.project else { return nil }
		return AttachmentOverviewViewModel(with: project)
	}

	func viewModelForStatistics() -> StatisticsViewModel? {

		guard let project = self.document.project else { return nil }
		return StatisticsViewModel(with: project)
	}
	func viewModelForInvoice() -> InvoiceViewModel? {

		guard let project = self.document.project else { return nil }
		return InvoiceViewModel(with: project)
	}

	let sessionCancelConfirmation = Property<PomodoroController.SessionCancelConfirmationInfo?>(nil)
}
