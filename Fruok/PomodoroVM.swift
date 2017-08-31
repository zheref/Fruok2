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
		case sessionCanceled
		case pauseRunning
		case pauseFinished

		var canStartSession: Bool {
			switch self {
			case .beforeFirstRun, .sessionFinished, .pauseFinished, .sessionCanceled:
				return true
			case .sessionRunning, .pauseRunning:
				return false
			}
		}
	}

	struct UIState {
		enum Color {
			case red; case blue
		}
		let progressLabesString: String
		let initialStartButtonVisisble: Bool
		let startNewSessionButtonVisible: Bool
		let startPauseButtonVisible: Bool
		let cancelButtonText: String
		let startButtonText: String = NSLocalizedString("Start Again", comment: "Start new session")
		let color: UIState.Color

		static var initial: UIState {
			return UIState(progressLabesString: "", initialStartButtonVisisble: true, startNewSessionButtonVisible: false, startPauseButtonVisible: false, cancelButtonText: "", color: .red)
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

	private func reflectLifeCycleChange(oldValue: LifeCycle?) {

		let uiState: UIState

		switch self.lifeCyclePhase {

		case .beforeFirstRun:

			uiState = UIState(
				progressLabesString: NSLocalizedString("Start", comment: "Start pomodoro sesion status"),
				initialStartButtonVisisble: true,
				startNewSessionButtonVisible: false,
				startPauseButtonVisible: false,
				cancelButtonText: NSLocalizedString("Cancel", comment: "Cancel pomodoro view"),
				color: .red
			)

		case .sessionRunning(pomodoroLog: let log):

			let timeString: String
			if let session = log.session, let startDate = session.startDate as? Date {

				let displaySeconds = max(session.duration - Date().timeIntervalSince(startDate), 0.0)
				let minutes: Int = Int(floor(displaySeconds / 60))
				let seconds: Int = Int(displaySeconds) - minutes * 60
				timeString = String(format: "%02u:%02u", minutes, seconds) as String
			} else {
				timeString = "??:??"
			}

			uiState = UIState(
				progressLabesString: timeString,
				initialStartButtonVisisble: false,
				startNewSessionButtonVisible: false,
				startPauseButtonVisible: false,
				cancelButtonText: NSLocalizedString("Abort", comment: "Abort pomodoro session"),
				color: .red
			)

		case .sessionFinished,
		     .sessionCanceled:
			uiState = UIState(
				progressLabesString: NSLocalizedString("Done", comment: "Pomodoro session finished status"),
				initialStartButtonVisisble: false,
				startNewSessionButtonVisible: true,
				startPauseButtonVisible: true,
				cancelButtonText: NSLocalizedString("Done", comment: "Pomodoro view dismiss"),
				color: .red)
		case .pauseRunning:

			let timeString: String
			if let (startDate, duration) = self.pauseInfo {

				let displaySeconds = max(duration - Date().timeIntervalSince(startDate), 0.0)
				let minutes: Int = Int(floor(displaySeconds / 60))
				let seconds: Int = Int(displaySeconds) - minutes * 60
				timeString = String(format: "%02u:%02u", minutes, seconds) as String
			} else {
				timeString = "??:??"
			}

			uiState = UIState(
				progressLabesString: timeString,
				initialStartButtonVisisble: false,
				startNewSessionButtonVisible: false,
				startPauseButtonVisible: false,
				cancelButtonText: NSLocalizedString("Cancel", comment: "Cancel pomodoro pause"),
				color: .blue
			)
		case .pauseFinished:

			uiState = UIState(
				progressLabesString: NSLocalizedString("Done", comment: "Pomodoro pause finished status"),
				initialStartButtonVisisble: false,
				startNewSessionButtonVisible: true,
				startPauseButtonVisible: false,
				cancelButtonText: NSLocalizedString("Done", comment: "Pomodoro view dismiss"),
				color: .red)
		}

		self.uiState.value = uiState
	}

	var pauseInfo: (startDate: Date, duration: TimeInterval)? = nil

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
				self.lifeCyclePhase = .sessionCanceled // should not happen
			}
		}
		do { try self.task.managedObjectContext?.save()} catch {}
	}

	let uiState = Property<UIState>(UIState.initial)
	let taskName = Property<String>("")
	let subtaskNames = Property<(selected: Int, names:[String])>(selected: 0, names:[""])

	func userWantsStartPomodorSession() {

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

	func timerFunction() {

		switch self.lifeCyclePhase {

		case .sessionRunning(pomodoroLog: let log):

			guard let session = log.session else {
				self.lifeCyclePhase = .beforeFirstRun // should not happen
				return
			}
			guard
				let startDate = session.startDate as? Date,
				NSDate().timeIntervalSince(startDate) < session.duration else {
				self.finishSession()
				return
			}

			self.lifeCyclePhase = .sessionRunning(pomodoroLog: log)
			DispatchQueue.main.after(when: 0.1, block: self.timerFunction)

		case .pauseRunning:
			guard let (startDate, duration) = self.pauseInfo else {
				self.lifeCyclePhase = .pauseFinished // should not happen
				return
			}

			guard NSDate().timeIntervalSince(startDate) < duration else {
				self.lifeCyclePhase = .pauseFinished
				return
			}

			self.lifeCyclePhase = .pauseRunning
			DispatchQueue.main.after(when: 0.1, block: self.timerFunction)

		default:
			break
		}
	}
	func userWantsChangeSubtask(_ index: Int) {

		let newSelectedSubtask: Subtask? = index < self.subtasksToDo.count ? self.subtasksToDo[index] : nil

		self.changeSelectedSubtask(to: newSelectedSubtask)
	}

	func userWantsCancelPomodoroSession() {

		self.lifeCyclePhase = .sessionCanceled
		NotificationCenter.default.post(name: .TRHidePomodoroSession, object: self)
	}
}
