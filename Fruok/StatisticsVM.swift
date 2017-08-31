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

extension DateFormatter {

	static let chartFormatter: DateFormatter = {

		let formatter = DateFormatter()
		formatter.timeStyle = .none
		formatter.dateStyle = .short
		return formatter
	}()
}

class StatisticsViewModel: NSObject, MVVMViewModel {

	enum ChartGroupMode {
		case date(ChartData<Date, Task>?)
		case task(ChartData<Task, Task>?)
	}

	typealias MODEL = Project
	@objc private let project: Project
	required init(with model: Project) {
		self.project = model
		super.init()
		self.updateChartData()
	}

	func updateChartData() {

		let taskFetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
		taskFetchRequest.predicate = NSPredicate(format: "state.project == %@", self.project)
		let tasks: NSOrderedSet

		do { tasks = try NSOrderedSet(array:(self.project.managedObjectContext?.fetch(taskFetchRequest) ?? [])) } catch { tasks = NSOrderedSet() }

		switch self.sessionFilterViewModel.groupMode.value {

		case .date:

			let dayStarts = self.sessionFilterViewModel.dateRange.value.dayStarts

			let perDay: [Date:[PomodoroSession]] = self.sessionFilterViewModel.sessions.grouping(by: { session in

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

			self.chartDataMode.value = .date(ChartData(
				data: perDayPerTask,
				globalKeySet: tasks,
				xKeySorter: <,
				yKeySorter: { ($0.name ?? "") < ($1.name ?? "") },
				xKeyLabelProvider: { DateFormatter.chartFormatter.string(from: $0) },
				yKeyLabelProvider: { $0.name ?? "" }
			))
		case .task:

			let perTask: [Task:[PomodoroSession]] = self.sessionFilterViewModel.sessions.grouping(by: { session in

				if let task = session.task {
					return task
				} else {
					return tasks[0] as! Task
				}
			})

			var perTaskPerTask: [Task: [Task:[PomodoroSession]]] = [:]

			for (task, sessions) in perTask {
				perTaskPerTask[task] = [task: sessions]
			}

			let chartData = ChartData(
				data: perTaskPerTask,
				globalKeySet: tasks,
				xKeySorter: {
					(perTaskPerTask[$0]![$0]!.reduce(0.0, {
						sum, session in
						return sum + session.totalDuration
					})) > (perTaskPerTask[$1]![$1]!.reduce(0.0, {
						sum, session in
						return sum + session.totalDuration
					}))
				},
				yKeySorter: { ($0.name ?? "") < ($1.name ?? "") },
				xKeyLabelProvider: { $0.name ?? "" },
				yKeyLabelProvider: { $0.name ?? "" }
				)
			self.chartDataMode.value = .task(chartData)
		}
	}

	lazy var sessionFilterViewModel: SessionFilterViewModel = {

		let filterViewModel = SessionFilterViewModel(with: self.project)
		filterViewModel.delegate = self
		return filterViewModel
	}()
	//let chartData = Property<ChartData<Date, Task>?>(nil)
	let chartDataMode = Property<ChartGroupMode>(.date(nil))
}

extension StatisticsViewModel: SessionFilterViewModelDelegate {

	func sessionFilterViewModelDidChangeSessions(_ sessionFilter: SessionFilterViewModel) {
		self.updateChartData()
	}
	func sessionFilterViewModelDidChangeGroupMode(_ sessionFilter: SessionFilterViewModel) {
		self.updateChartData()
	}

}
