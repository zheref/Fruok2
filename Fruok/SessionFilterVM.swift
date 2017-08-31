//
//  SessionFilterVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 30.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

struct DateRange {

	let date: Date
	let interval: TimeInterval

	var endDate: Date {

		return date.addingTimeInterval(self.interval)
	}

	static var today: DateRange {

		let date = Date().startOfDay
		let interval: TimeInterval
		if let endOfDay = date.endOfDay {
			interval = endOfDay.timeIntervalSince(date)
		} else {
			interval = TimeInterval(24 * 60 * 60)
		}

		return DateRange(date: date, interval: interval)
	}

	var dayStarts: [Date] {

		var dayComponents = DateComponents()
		dayComponents.day = 1

		var dayStarts: [Date] = []
		var currentDate = self.date.startOfDay

		while currentDate < self.endDate {

			dayStarts.append(currentDate)
			currentDate = Calendar.current.date(byAdding: dayComponents, to: currentDate) ?? currentDate.addingTimeInterval(24 * 60 * 60).startOfDay
		}

		return dayStarts
	}
}

protocol SessionFilterViewModelDelegate: class {

	func sessionFilterViewModelDidChangeSessions(_ sessionFilter: SessionFilterViewModel)
	func sessionFilterViewModelDidChangeGroupMode(_ sessionFilter: SessionFilterViewModel)
}

class SessionFilterViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Project
	@objc private let project: Project
	required init(with model: Project) {
		self.project = model
		super.init()

		self.dateRange.value = DateRange.today

		self.update()
	}

	enum GroupMode: Int {
		case date
		case task
	}

	weak var delegate: SessionFilterViewModelDelegate?

	private var sortedTasks: [Task] = []
	private var selectedTask: Task? = nil

	let dateRange = Property<DateRange>(DateRange.today)
	let groupMode = Property<GroupMode>(.date)
	let taskNames = Property<(selectedIndex: Int, names: [String])>(selectedIndex: 0, names: [""])

	var sessions: [PomodoroSession] = []

	func update() {

		let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
		let tasks: [Task]

		do { tasks = try self.project.managedObjectContext?.fetch(fetchRequest) ?? [] } catch { tasks = []}

		self.sortedTasks = tasks.sorted { (t1, t2) -> Bool in
			(t1.name ?? "") < (t2.name ?? "")
		}
		self.selectedTask = nil

		self.updateTaskNames()
		self.collectData()
	}

	func collectData() {

		let fetchRequest: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()

		var subpredicates: [NSPredicate] = []

		subpredicates.append(NSPredicate(format: "startDate >= %@ && startDate <= %@", self.dateRange.value.date as NSDate, self.dateRange.value.endDate as NSDate))

		subpredicates.append(NSPredicate(format: "task != nil"))

		if let selectedTask = self.selectedTask {

			subpredicates.append(NSPredicate(format: "task == %@", selectedTask))
		}

		fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)

		do { self.sessions = try self.project.managedObjectContext?.fetch(fetchRequest) ?? [] } catch { self.sessions = [] }
	}

	func updateTaskNames() {

		let selectedIndex: Int

		if let selectedTask = self.selectedTask {
			if let index = self.sortedTasks.index(of: selectedTask) {
				selectedIndex = index + 1
			} else {
				selectedIndex = 0
			}
		} else {
			selectedIndex = 0
		}
		self.taskNames.value = (
			selectedIndex: selectedIndex,
			names: [NSLocalizedString("All Tasks", comment: "All tasks statistics")] + self.sortedTasks.map { $0.name ?? "" })
		
	}

	func userWantsSetDateRange(_ range: DateRange) {

		self.dateRange.value = range
		self.collectData()
		self.delegate?.sessionFilterViewModelDidChangeSessions(self)
	}

	func userWantsSelectTaskAtIndex(_ index: Int) {

		defer {
			self.collectData()
			self.delegate?.sessionFilterViewModelDidChangeSessions(self)
		}

		if index == 0 {
			self.selectedTask = nil
			return
		}

		self.selectedTask = self.sortedTasks[index - 1]
		self.updateTaskNames()
	}

	func userWantsSetGroupMode(_ mode: GroupMode) {

		self.groupMode.value = mode
		self.delegate?.sessionFilterViewModelDidChangeGroupMode(self)
	}

	func userWantsDateRangeValidation(_ dateRange: (date: Date, timeInterval: TimeInterval)) -> (date: Date, timeInterval: TimeInterval) {

		let adjustedDate = dateRange.date.startOfDay
		let proposedEndDate = dateRange.date.addingTimeInterval(dateRange.timeInterval)
		let adjustedEndDate = proposedEndDate.endOfDay ?? proposedEndDate
		let interval = adjustedEndDate.timeIntervalSince(adjustedDate)

		return (date: adjustedDate, timeInterval: interval)
	}
}
