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

	private enum LifeCycle {
		case beforeFirstRun
		case sessionRunning(pomodoroLog: PomodoroLog)
		case sessionFinished(session: PomodoroSession)
		case pauseRunning(startDate: Date, duration: TimeInterval)

		var canStartSession: Bool {
			switch self {
			case .beforeFirstRun, .sessionFinished:
				return true
			case .sessionRunning, .pauseRunning:
				return false
			}
		}
	}

	struct UIState {
		enum Color {
			case pomodoro; case pause
		}
		enum TextControlState {
			case visible(String)
			case hidden
		}
		let progressLabel: TextControlState
		let startButton: TextControlState
		let pauseButton: TextControlState
		let cancelButton: TextControlState
		let takeBreakLabelVisible: Bool
		let taskInfoVisible: Bool
		let color: UIState.Color

		static var initial: UIState {

			return UIState(
				progressLabel: .hidden,
				startButton: .hidden,
				pauseButton: .hidden,
				cancelButton: .hidden,
				takeBreakLabelVisible: false,
				taskInfoVisible: false,
				color: .pomodoro
			)
		}
	}

	typealias MODEL = Task
	@objc private let task: Task

	private var lifeCyclePhase = LifeCycle.beforeFirstRun {
		didSet {
			self.reflectLifeCycleChange(oldValue: oldValue)
		}
	}

	var sessionRunning: Bool {

		if case .sessionRunning = self.lifeCyclePhase {
			return true
		} else {
			return false
		}
	}

	private var subtasksToDo: [Subtask] = []
	private var selectedSubtask: Subtask?// must be in sync with currentPomodoroLog

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

		self.lifeCyclePhase = .beforeFirstRun
		self.updateSubtaskUI()
		self.reflectLifeCycleChange(oldValue: nil) // property observers not getting called in init
	}

	private func formatTime(seconds: TimeInterval) -> String {

		let minutes: Int = Int(floor(seconds / 60))
		let remainingSeconds: Int = Int(seconds) - minutes * 60
		return String(format: "%02u:%02u", minutes, remainingSeconds) as String
	}

	private func reflectLifeCycleChange(oldValue: LifeCycle?) {

		let uiState: UIState

		switch self.lifeCyclePhase {

		case .beforeFirstRun:

			uiState = UIState(
				progressLabel: .visible(self.formatTime(seconds: PomodoroSession.defaultDuration)),
				startButton: .visible(NSLocalizedString("START", comment: "Start pomodoro sesion status")),
				pauseButton: .hidden,
				cancelButton: .visible(NSLocalizedString("CANCEL", comment: "Cancel pomodoro view")),
				takeBreakLabelVisible: false,
				taskInfoVisible: true,
				color: .pomodoro
		)

		case .sessionRunning(pomodoroLog: let log):

			let timeString: String
			if let session = log.session, let startDate = session.startDate as? Date {

				let displaySeconds = max(session.duration - Date().timeIntervalSince(startDate), 0.0)
				timeString = self.formatTime(seconds: displaySeconds)
			} else {
				timeString = "??:??"
			}

			uiState = UIState(
				progressLabel: .visible(timeString),
				startButton: .hidden,
				pauseButton: .visible(NSLocalizedString("PAUSE", comment: "Pause pomodoro session")),
				cancelButton: .visible(NSLocalizedString("ABORT", comment: "Abort pomodoro session")),
				takeBreakLabelVisible: false,
				taskInfoVisible: true,
				color: .pomodoro
			)

		case .sessionFinished:

			uiState = UIState(
				progressLabel: .visible(self.formatTime(seconds: PomodoroSession.defaultShortBreakDuration)),
				startButton: .visible(NSLocalizedString("START", comment: "Start pomodoro break")),
				pauseButton: .hidden,
				cancelButton: .visible(NSLocalizedString("SKIP", comment: "Skip pomodoro break")),
				takeBreakLabelVisible: true,
				taskInfoVisible: false,
				color: .pause
			)

		case .pauseRunning(let startDate, let duration):

			let displaySeconds = max(duration - Date().timeIntervalSince(startDate), 0.0)
			let timeString = self.formatTime(seconds: displaySeconds)

			uiState = UIState(
				progressLabel: .visible(timeString),
				startButton: .hidden,
				pauseButton: .hidden,
				cancelButton: .visible(NSLocalizedString("Skip", comment: "Skip pomodoro break")),
				takeBreakLabelVisible: true,
				taskInfoVisible: false,
				color: .pause
			)
		}

		self.uiState.value = uiState
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

	func changeSelectedSubtask(to newSelectedSubtask: Subtask?) {

		defer { self.updateSubtaskUI() }

		if self.selectedSubtask == newSelectedSubtask {
			return
		}

		switch self.lifeCyclePhase {
		case .sessionRunning(pomodoroLog: let log):

			guard let session = log.session else { return }
			guard let newLog = session.startLogForSubtask(newSelectedSubtask, previousLog: log) else {return}
			self.selectedSubtask = newSelectedSubtask
			self.lifeCyclePhase = .sessionRunning(pomodoroLog: newLog)
			do { try self.task.managedObjectContext?.save()} catch {}

		default:
			self.selectedSubtask = newSelectedSubtask
			return
		}
	}

	func finishSession() {

		if case let .sessionRunning(pomodoroLog: log) = self.lifeCyclePhase {
			log.session?.finishSession(log)
			if let session = log.session {
				self.lifeCyclePhase = .sessionFinished(session: session)
			} else {
				self.lifeCyclePhase = .beforeFirstRun // should not happen
			}
		}
		do { try self.task.managedObjectContext?.save()} catch {}
	}

	let uiState = Property<UIState>(UIState.initial)
	let taskName = Property<String>("")
	let subtaskNames = Property<(selected: Int, names:[String])>(selected: 0, names:[""])

	func timerFunction() {

		switch self.lifeCyclePhase {

		case .sessionRunning(pomodoroLog: let log):

			guard
				let session = log.session,
				let startDate = session.startDate as? Date else {

					self.lifeCyclePhase = .beforeFirstRun // should not happen
				return
			}
			guard
				NSDate().timeIntervalSince(startDate) < session.duration else {

				NotificationCenter.default.post(name: .TRPomodoroSessionEndedRegularly, object: self)
				self.finishSession()
				self.userWantsStartBreak()
				return
			}

			self.lifeCyclePhase = .sessionRunning(pomodoroLog: log)
			DispatchQueue.main.after(when: 0.1, block: self.timerFunction)

		case .pauseRunning(let startDate, let duration):

			guard NSDate().timeIntervalSince(startDate) < duration else {
				NotificationCenter.default.post(name: .TRPomodoroBreakEndedRegularly, object: self)
				self.lifeCyclePhase = .beforeFirstRun
				return
			}

			self.lifeCyclePhase = .pauseRunning(startDate: startDate, duration: duration)
			DispatchQueue.main.after(when: 0.1, block: self.timerFunction)

		default:
			break
		}
	}

	private func userWantsStartPomodorSession() {

		if !self.lifeCyclePhase.canStartSession {
			return
		}

		guard let session = PomodoroSession.makeSessionWithTask(self.task) else {
			return
		}
		guard let log = session.startLogForSubtask(self.selectedSubtask, previousLog: nil) else {
			return
		}
		self.lifeCyclePhase = .sessionRunning(pomodoroLog: log)
		self.timerFunction()
	}

	private func userWantsStartBreak() {

		self.lifeCyclePhase = .pauseRunning(startDate: Date(), duration: PomodoroSession.defaultShortBreakDuration)
		self.timerFunction()
	}

	func userWantsChangeSubtask(_ index: Int) {

		let newSelectedSubtask: Subtask? = index < self.subtasksToDo.count ? self.subtasksToDo[index] : nil

		self.changeSelectedSubtask(to: newSelectedSubtask)
	}

	private func userWantsCancelPomodoroSession() {

		// The document handles this, and will call finishSession()
		NotificationCenter.default.post(name: .TRHidePomodoroSession, object: self)
	}

	func userWantsStart() {

		switch self.lifeCyclePhase {

		case .beforeFirstRun:
				self.userWantsStartPomodorSession()
				return
		case .sessionFinished:
			self.userWantsStartBreak()
			return
		case .pauseRunning,
		     .sessionRunning:
			break

		}
	}

	func userWantsCancel() {

		switch self.lifeCyclePhase {

		case .pauseRunning,
		     .sessionFinished:
			self.lifeCyclePhase = .beforeFirstRun
		case .sessionRunning,
		     .beforeFirstRun:
			self.userWantsCancelPomodoroSession()
		}
	}
}
