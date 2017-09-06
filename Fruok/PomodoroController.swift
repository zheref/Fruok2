//
//  PomodoroController.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

extension Notification.Name {

	static let TRHidePomodoroSession = Notification.Name("TRHidePomodoroSession")
	static let TRPomodoroSessionEndedRegularly = Notification.Name("TRPomodoroSessionEndedRegularly")
	static let TRPomodoroBreakEndedRegularly = Notification.Name("TRPomodoroBreakEndedRegularly")

}

class PomodoroController: NSObject {

	var currentPomodoroObjects: (document: FruokDocument, viewModel: PomodoroViewModel, statusItem: NSStatusItem)?

	override init() {

		super.init()
		
		NotificationCenter.default.reactive.notification(name: .TRHidePomodoroSession, object: nil).observeNext { note in

			guard
				let viewModel = note.object as? PomodoroViewModel,
				viewModel == self.currentPomodoroObjects?.viewModel else {
					return
			}

			self.userWantsHidePomodoroSession(pomodoroViewModel: viewModel)

			}.dispose(in: bag)

		NotificationCenter.default.reactive.notification(name: .TRPomodoroSessionEndedRegularly, object: nil).observeNext { note in

			guard
				let viewModel = note.object as? PomodoroViewModel,
				viewModel == self.currentPomodoroObjects?.viewModel else {
					return
			}

			self.currentPomodoroObjects?.document.contentViewModel?.action.value =
			.notifySessionEnded(notification: NSLocalizedString("Pomodoro Session Ended", comment: "Pomodoro Session Ended user notification"))

			}.dispose(in: bag)

		NotificationCenter.default.reactive.notification(name: .TRPomodoroBreakEndedRegularly, object: nil).observeNext { note in

			guard
				let viewModel = note.object as? PomodoroViewModel,
				viewModel == self.currentPomodoroObjects?.viewModel else {
					return
			}

			self.currentPomodoroObjects?.document.contentViewModel?.action.value =
			.notifyBreakEnded(notification: NSLocalizedString("Break Ended", comment: "Pomodoro Break Ended user notification"))
			
			}.dispose(in: bag)
	}

	struct SessionCancelConfirmationInfo {

		let question: String
		let callback: () -> Void
	}

	public func documentRequestPomodoroStart(_ document: FruokDocument, forTask task: Task) {

		if !(self.isCurrentSessionRunning) {
			self.doStartPomodoroSession(document: document, task: task)
			return
		}

		let info = SessionCancelConfirmationInfo(
			question: NSLocalizedString("Do you really want to abort this session?", comment: "Abort pomodoro session warning"),
			callback: { [weak self] in

				self?.currentPomodoroObjects?.viewModel.finishSession()
				self?.doStartPomodoroSession(document: document, task: task)
		})
		self.currentPomodoroObjects?.document.contentViewModel?.sessionCancelConfirmation.value = info
	}

	var isCurrentSessionRunning: Bool {
		return self.currentPomodoroObjects?.viewModel.sessionRunning ?? false
	}
	private func doStartPomodoroSession(document: FruokDocument, task: Task) {

		let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
		statusItem.button?.title = ""
		let icon = NSApp.applicationIconImage
		icon?.size = NSSize(width: NSStatusBar.system().thickness, height: NSStatusBar.system().thickness)
		statusItem.button?.image = icon
		statusItem.button?.target = self
		statusItem.button?.action = #selector(PomodoroController.bringPomodoroWindowToForeground(_:))
		self.currentPomodoroObjects?.document.contentViewModel?.pomodoroVisible.value = nil
		let pomodoroViewModel = PomodoroViewModel(with: task)
		self.currentPomodoroObjects = (document: document, viewModel: pomodoroViewModel, statusItem: statusItem)
		self.currentPomodoroObjects?.document.contentViewModel?.pomodoroVisible.value = pomodoroViewModel
	}

	func bringPomodoroWindowToForeground(_ sender: Any?) {

		if let windowControllers = self.currentPomodoroObjects?.document.windowControllers {

			for windowController in windowControllers {

				windowController.window?.makeKeyAndOrderFront(nil)
			}
		}
		NSApp.activate(ignoringOtherApps: true)
	}
	private func doAbortAndHidePomodoroSession() {

		self.currentPomodoroObjects?.document.contentViewModel?.pomodoroVisible.value = nil
		self.currentPomodoroObjects = nil
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
		self.currentPomodoroObjects?.document.contentViewModel?.sessionCancelConfirmation.value = info
		
	}

	func documentWillClose(_ document: FruokDocument) {

		if self.currentPomodoroObjects?.document == document {
			self.doAbortAndHidePomodoroSession()
		}
	}
}
