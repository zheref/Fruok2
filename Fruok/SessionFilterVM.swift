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
	let endDate: Date

	init(date: Date, interval: TimeInterval) {

		self.init(startDate: date, endDate: date.addingTimeInterval(interval))
	}

	init(startDate: Date, endDate: Date) {

		self.date = startDate
		self.endDate = endDate
	}

	var interval: TimeInterval {
		return self.endDate.timeIntervalSince(self.date)
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

enum DateRangePreset {
	case custom(DateRange)
	case thisWeek
	case thisMonth
	case lastWeek
	case lastMonth
	case thisYear
	case allData(DateRange)

	var dateRange: DateRange {

		switch self {
		case .custom(let range):
			return range
		case .allData(let range):
			return range
		case .thisWeek:
			var start = Date()
			var interval: TimeInterval = 0
			_ = Calendar.current.dateInterval(of: .weekOfYear, start: &start, interval: &interval, for: Date())
			return DateRange(date: start, interval: interval)
		case .thisMonth:
			var start = Date()
			var interval: TimeInterval = 0
			_ = Calendar.current.dateInterval(of: .month, start: &start, interval: &interval, for: Date())
			return DateRange(date: start, interval: interval)
		case .thisYear:
			var start = Date()
			var interval: TimeInterval = 0
			_ = Calendar.current.dateInterval(of: .year, start: &start, interval: &interval, for: Date())
			return DateRange(date: start, interval: interval)
		case .lastWeek:
			var start = Date()
			var interval: TimeInterval = 0
			_ = Calendar.current.dateInterval(of: .weekOfYear, start: &start, interval: &interval, for: Date())
			start  = start.addingTimeInterval(-4 * 60 * 60)
			_ = Calendar.current.dateInterval(of: .weekOfYear, start: &start, interval: &interval, for: start)
			return DateRange(date: start, interval: interval)
		case .lastMonth:
			var start = Date()
			var interval: TimeInterval = 0
			_ = Calendar.current.dateInterval(of: .month, start: &start, interval: &interval, for: Date())
			start  = start.addingTimeInterval(-4 * 60 * 60)
			_ = Calendar.current.dateInterval(of: .month, start: &start, interval: &interval, for: start)
			return DateRange(date: start, interval: interval)
		}
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

		self.update()
	}

	enum GroupMode: Int {
		case date
		case task
	}

	weak var delegate: SessionFilterViewModelDelegate?

	private var sortedTasks: [Task] = []
	private var selectedTask: Task? = nil

	let selectedDatePreset = Property<DateRangePreset>(.thisWeek)
	let groupMode = Property<GroupMode>(.date)
	let taskNames = Property<(selectedIndex: Int, names: [String])>(selectedIndex: 0, names: [""])
	let groupControlVisible = Property<Bool>(true)

	var sessions: [PomodoroSession] = []

	var dateRange: DateRange {
		return self.selectedDatePreset.value.dateRange
	}
	
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

		subpredicates.append(NSPredicate(format: "startDate >= %@ && startDate <= %@", self.selectedDatePreset.value.dateRange.date as NSDate, self.selectedDatePreset.value.dateRange.endDate as NSDate))

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

	func userWantsSetPeriodPreset(_ preset: DateRangePreset) {

		self.selectedDatePreset.value = preset
		self.collectData()
		self.delegate?.sessionFilterViewModelDidChangeSessions(self)
	}

	func userWantsSetDateRange(_ range: DateRange) {

		self.selectedDatePreset.value = .custom(range)
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

	func validateStartDateWithRange(_ range: DateRange) -> DateRange {

		let adjustedDate = range.date.startOfDay
		var adjustedEndDate = dateRange.endDate.endOfDay ?? dateRange.endDate

		if adjustedEndDate <= adjustedDate {
			adjustedEndDate = adjustedDate.endOfDay ?? adjustedDate.addingTimeInterval(60 * 60 * 24)
		}
		return DateRange(startDate: adjustedDate, endDate: adjustedEndDate)
	}

	func validateEndDateWithRange(_ range: DateRange) -> DateRange {

		var adjustedDate = range.date.startOfDay
		let adjustedEndDate = dateRange.endDate.endOfDay ?? dateRange.endDate

		if adjustedEndDate <= adjustedDate {
			adjustedDate = adjustedEndDate.startOfDay
		}
		return DateRange(startDate: adjustedDate, endDate: adjustedEndDate)
	}

	func allDataDateRange() -> DateRange {

		var sessions: [PomodoroSession]
		let fetchRequest: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
		do { sessions = try self.project.managedObjectContext?.fetch(fetchRequest) ?? [] } catch { sessions = [] }

		sessions.sort { (session1, session2) in

			return (session1.startDate as Date? ?? Date()) < (session2.startDate as Date? ?? Date())
		}

		let start = (sessions.first?.startDate as Date?)?.startOfDay ?? Date().startOfDay
		let end = (sessions.last?.startDate as Date?)?.endOfDay ?? Date()

		return DateRange(startDate: start, endDate: end)
	}
}
