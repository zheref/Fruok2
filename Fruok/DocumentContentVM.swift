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

extension Notification.Name {

	static let TRHidePomodoroSession = Notification.Name("TRHidePomodoroSession")
}

class DocumentContentViewModel: NSObject, MVVMViewModel {

	typealias MODEL = FruokDocument

	required init(with document: FruokDocument) {

		self.document = document
		super.init()

		NotificationCenter.default.reactive.notification(name: .TRHidePomodoroSession, object: nil).observeNext { note in

			if let viewModel = note.object as? PomodoroViewModel {
				self.userWantsHidePomodoroSession(pomodoroViewModel: viewModel)
			}
		}.dispose(in: bag)
	}

	let document: FruokDocument

	public enum ChildView: Int, OptionalRawValueRepresentable {

		case project
		case kanban
		case statistics
		case billing
	}

	private(set) var currentChildView: Observable<ChildView?> = Observable(.project)
	let pomodoroVisible = Property<PomodoroViewModel?>(nil)

	func changeCurrentChildView(to childView: ChildView) {

		if self.document.fileURL == nil {

			let context = UnsafeMutableRawPointer(bitPattern: childView.rawValue)!
			self.document.runModalSavePanel(for: .saveOperation, delegate: self, didSave: #selector(DocumentContentViewModel.changeCurrentChildViewAfterAveOperationOfDocument(_:didSave:context:)), contextInfo: context)
			return
		}

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

	func viewModelForStatistics() -> StatisticsViewModel? {

		guard let project = self.document.project else { return nil }
		return StatisticsViewModel(with: project)
	}
	func viewModelForInvoice() -> InvoiceViewModel? {

		guard let project = self.document.project else { return nil }
		return InvoiceViewModel(with: project)
	}


	struct SessionCancelConfirmationInfo {

		let question: String
		let callback: () -> Void
	}
	let sessionCancelConfirmation = Property<SessionCancelConfirmationInfo?>(nil)

	func userWantsStartPomodoroSession(for taskDetailViewModel: TaskDetailViewModel) {

		if !(self.pomodoroVisible.value?.sessionRunning ?? false) {
			self.doStartPomodoroSession(task: taskDetailViewModel.task)
			return
		}

		let info = SessionCancelConfirmationInfo(
			question: NSLocalizedString("Do you really want to abort this session?", comment: "Abort pomodoro session warning"),
			callback: { [weak self] in

				self?.pomodoroVisible.value?.finishSession()
				self?.doStartPomodoroSession(task: taskDetailViewModel.task)
		})
		self.sessionCancelConfirmation.value = info
	}

	private func doStartPomodoroSession(task: Task) {

		let pomodoroViewModel = PomodoroViewModel(with: task)
		self.pomodoroVisible.value = pomodoroViewModel
	}

	private func doAbortAndHidePomodoroSession() {

		self.pomodoroVisible.value = nil
	}

	func userWantsHidePomodoroSession(pomodoroViewModel: PomodoroViewModel) {

		if !pomodoroViewModel.sessionRunning {
			self.doAbortAndHidePomodoroSession()
			return
		}

		let info = SessionCancelConfirmationInfo(
			question: NSLocalizedString("Do you really want to abort this session?", comment: "Abort pomodoro session warning"),
			callback: { [weak self] in

				pomodoroViewModel.finishSession()
				self?.doAbortAndHidePomodoroSession()
		})
		self.sessionCancelConfirmation.value = info

	}
}
