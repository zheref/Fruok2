//
//  PomodoroVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 27.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

class PomodoroViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Task
	@objc private let task: Task

	private var pomodoroSession: PomodoroSession?
	private var currentPomodoroLog: PomodoroLog?
	private var subtasksToDo: [Subtask] = []
	private var selectedSubtask: Subtask?// must be in sync with currentPomodoroLog
	var sessionIsRunning = false {
		didSet {
			if oldValue != self.sessionIsRunning {
				self.sessionIsRunningDidChange()
			}
		}
	}
	private var runningTimer: Timer?

	required init(with model: MODEL) {
		self.task = model
		super.init()

		self.reactive.keyPath(#keyPath(PomodoroViewModel.task.name), ofType: Optional<String>.self, context: .immediateOnMain)
			.map { $0 ?? "" }
			.bind(to: self.taskName)
			.dispose(in: bag)

		NotificationCenter.default.reactive.notification(name: .NSManagedObjectContextObjectsDidChange, object: self.task.managedObjectContext).observeNext { note in

			let changedSubtasks = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]
				.map { note.userInfo?[$0] as? Set<AnyHashable> }
				.flatMap { $0 }
				.flatMap { $0 }
				.filter { $0 is Subtask }

			if changedSubtasks.count > 0 {
				self.subtasksDidChange()
			}
		}.dispose(in: bag)

		self.subtasksDidChange()
		self.selectedSubtask = self.subtasksToDo.first
		self.updateSubtaskUI()
		self.reflectCurrentSessionRunningTime()
	}

	func subtasksDidChange() {

		let newSubtasks = self.task.subtasks == nil ? [] : self.task.subtasks!.array.flatMap { $0 as? Subtask }.filter { !$0.done }

		let nextIndex: Int

		// Did we have a specific subtask selected?
		if let currentSubtask = self.selectedSubtask {

			// If it is still around, keep it
			if let index = newSubtasks.index(of: currentSubtask) {

				nextIndex = index
			} else { // Else, select the first new one
				nextIndex = 0
			}
		// If we didnt have a specific subtask selected, don't select one
		} else {
			nextIndex = newSubtasks.count
		}

		self.subtasksToDo = newSubtasks

		let newSubtask = nextIndex < newSubtasks.count ? newSubtasks[nextIndex] : nil
		self.changeSelectedSubtask(to: newSubtask)
	}

	func updateSubtaskUI() {

		let subtaskNames = self.subtasksToDo.map { $0.name ?? "" } + [NSLocalizedString("Other", comment: "Pomodoro no current subtasks")]
		let index: Int

		if let selectedSubtask = self.selectedSubtask {

			index = self.subtasksToDo.index(of: selectedSubtask) ?? self.subtasksToDo.count
		} else {
			index = self.subtasksToDo.count
		}

		self.subtaskNames.value = (index, subtaskNames)
	}

	func sessionIsRunningDidChange() {

		if self.sessionIsRunning {

			self.runningTimer?.invalidate()
			self.reflectCurrentSessionRunningTime()
			let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(PomodoroViewModel.reflectCurrentSessionRunningTime), userInfo: nil, repeats: true)
			self.runningTimer = timer

		} else {

			self.runningTimer?.invalidate()
			self.reflectCurrentSessionRunningTime()
			self.finishSession()
		}
	}

	func reflectCurrentSessionRunningTime() {

		let secondsRunning: TimeInterval
		let sessionDuration: TimeInterval

		if let session = self.pomodoroSession, let startDate = session.startDate {

			secondsRunning = Date().timeIntervalSince(startDate as Date)
			sessionDuration = session.duration

			if session.duration < secondsRunning {
				self.sessionIsRunning = false
				self.timeString.value = NSLocalizedString("Done", comment: "Pomodoro finished")
				return
			}
		} else {
			secondsRunning = 0
			sessionDuration = PomodoroSession.defaultDuration
		}

		let displaySeconds = max(sessionDuration - secondsRunning, 0.0)
		let minutes: Int = Int(floor(displaySeconds / 60))
		let seconds: Int = Int(displaySeconds) - minutes * 60
		let timeString = NSString(format: "%02u:%02u", minutes, seconds)
		self.timeString.value = timeString as String

	}

	func changeSelectedSubtask(to newSelectedSubtask: Subtask?) {

		if self.selectedSubtask == newSelectedSubtask {
			self.updateSubtaskUI()
			return
		}

		self.selectedSubtask = newSelectedSubtask

		if !self.sessionIsRunning {

			return
		}

		self.currentPomodoroLog = self.pomodoroSession?.startLogForSubtask(self.selectedSubtask, previousLog: self.currentPomodoroLog)
		self.selectedSubtask = newSelectedSubtask
		do { try self.task.managedObjectContext?.save()} catch {}

		self.updateSubtaskUI()
	}

	func finishSession() {

		self.pomodoroSession?.finishSession(self.currentPomodoroLog)
		do { try self.task.managedObjectContext?.save()} catch {}
	}

	let taskName = Property<String>("")
	let subtaskNames = Property<(selected: Int, names:[String])>(selected: 0, names:[""])
	let startButtonVisible = Property<Bool>(true)
	let timeString = Property<String>("--:--")

	func userWantsStartPomodorSession() {

		if self.sessionIsRunning {
			return
		}

		self.pomodoroSession = PomodoroSession.makeSessionWithTask(self.task)
		self.currentPomodoroLog = self.pomodoroSession?.startLogForSubtask(self.selectedSubtask, previousLog: nil)
		self.sessionIsRunning = true
		self.startButtonVisible.value = false
	}

	func userWantsChangeSubtask(_ index: Int) {

		let newSelectedSubtask: Subtask? = index < self.subtasksToDo.count ? self.subtasksToDo[index] : nil

		self.changeSelectedSubtask(to: newSelectedSubtask)
	}

	func userWantsCancelPomodoroSession() {

		NotificationCenter.default.post(name: .TRHidePomodoroSession, object: self)
	}
}
