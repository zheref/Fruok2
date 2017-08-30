//
//  StatisticsVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 28.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit

extension Date {
	var startOfDay: Date {
		return Calendar.current.startOfDay(for: self)
	}

	var endOfDay: Date? {
		var components = DateComponents()
		components.day = 1
		components.second = -1
		return Calendar.current.date(byAdding: components, to: startOfDay)
	}
}

extension Array {

	func grouping<Key: Hashable>(by keyForValue: ((Element) -> Key), sortedBy: ((Element, Element) -> ComparisonResult)? = nil) -> [Key: [Element]] {

		var result: [Key: [Array.Element]] = [:]

		for element in self {

			let key = keyForValue(element)
			if let sortedBy = sortedBy {
				var elements = (result[key] ?? [])
				let index = elements.binaryInsertion(search: element, comparator: sortedBy)
				elements.insert(element, at: index)
				result[key] = elements
			} else {
				result[key] = (result[key] ?? []) + [element]
			}
		}

		return result
	}
}


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
class StatisticsViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Project
	@objc private let project: Project
	required init(with model: Project) {
		self.project = model
		super.init()

		self.dateRange.value = DateRange.today

		self.update()
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

	func collectData() {

		let taskFetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
		taskFetchRequest.predicate = NSPredicate(format: "state.project == %@", self.project)
		let tasks: NSOrderedSet

		do { tasks = try NSOrderedSet(array:(self.project.managedObjectContext?.fetch(taskFetchRequest) ?? [])) } catch { tasks = NSOrderedSet() }

//		let tasks: NSOrderedSet = (self.project.value(forKeyPath: "taskStates.tasks") as? NSOrderedSet) ?? NSOrderedSet()

		let fetchRequest: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()

		var subpredicates: [NSPredicate] = []

		subpredicates.append(NSPredicate(format: "startDate >= %@ && startDate <= %@", self.dateRange.value.date as NSDate, self.dateRange.value.endDate as NSDate))

		subpredicates.append(NSPredicate(format: "task != nil"))

		if let selectedTask = self.selectedTask {

			subpredicates.append(NSPredicate(format: "task == %@", selectedTask))
		}

		fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)

		let sessions: [PomodoroSession]

		do { sessions = try self.project.managedObjectContext?.fetch(fetchRequest) ?? [] } catch { sessions = [] }

		let dayStarts = self.dateRange.value.dayStarts

		let perDay: [Date:[PomodoroSession]] = sessions.grouping(by: { session in

			let index = dayStarts.binaryInsertion(search: session.startDate as! Date, options: .last)

			precondition(index > 0)

			return dayStarts[index - 1]
		})

		var perDayPerTask: [Date:[Task: [PomodoroSession]]] = [:]

		for day in dayStarts {

			let perTask: [Task: [PomodoroSession]] = (perDay[day] ?? []).grouping(by: { session in

				return session.task!
			})

			perDayPerTask[day] = perTask
		}

		self.chartData.value = ChartData(data: perDayPerTask, globalKeySet: tasks)
	}

	private var sortedTasks: [Task] = []
	private var selectedTask: Task? = nil

	let dateRange = Property<DateRange>(DateRange.today)
	let taskNames = Property<(selectedIndex: Int, names: [String])>(selectedIndex: 0, names: [""])
	let chartData = Property<ChartData>(ChartData(data: [:], globalKeySet: NSOrderedSet()))

	func userWantsSetDateRange(_ range: DateRange) {

		self.dateRange.value = range
		self.collectData()
	}

	func userWantsSelectTaskAtIndex(_ index: Int) {

		defer {
			self.collectData()
		}

		if index == 0 {
			self.selectedTask = nil
			return
		}

		self.selectedTask = self.sortedTasks[index - 1]
		self.updateTaskNames()
	}

	func userWantsDateRangeValidation(_ dateRange: (date: Date, timeInterval: TimeInterval)) -> (date: Date, timeInterval: TimeInterval) {

		let adjustedDate = dateRange.date.startOfDay
		let proposedEndDate = dateRange.date.addingTimeInterval(dateRange.timeInterval)
		let adjustedEndDate = proposedEndDate.endOfDay ?? proposedEndDate
		let interval = adjustedEndDate.timeIntervalSince(adjustedDate)

		return (date: adjustedDate, timeInterval: interval)
	}
}
