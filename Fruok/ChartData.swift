//
//  ChartData.swift
//  Fruok
//
//  Created by Matthias Keiser on 30.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

class ChartData {

	private static let dateFormatter: DateFormatter = {

		let formatter = DateFormatter()
		formatter.timeStyle = .none
		formatter.dateStyle = .short
		return formatter
	}()

	init(data: [Date:[Task: [PomodoroSession]]], globalKeySet: NSOrderedSet) {
		self.data = data
		self.globalKeySet = globalKeySet
	}

	private let data: [Date:[Task: [PomodoroSession]]]
	private let globalKeySet: NSOrderedSet

	private var sortedXKeys: [Date] {
		return self.data.keys.sorted()
	}
	var xAxisLabels: [String] {

		return self.sortedXKeys.map { ChartData.dateFormatter.string(from: $0)}
	}

	func sortedYValues(at index: Int) -> [TimeInterval?] {

		guard let yMap = self.data[self.sortedXKeys[index]] else { return []}

		let sortedValues: [TimeInterval?] = self.orderedDataSetKeys.map { task in

			guard let entries = yMap[task] else { return nil }

			return entries.reduce(TimeInterval(0.0), { time, session in

				return time + session.totalDuration
			})
		}

		return sortedValues
	}

	private lazy var orderedDataSetKeys: [Task] = {

		var keys: Set<Task> = []

		for dict in self.data.values {

			keys.formUnion(Set(dict.keys))
		}

		let sorted = keys.sorted { task1, task2 in

			return (task1.name ?? "") < (task2.name ?? "")
		}

		return sorted
	}()

	lazy var dataSetLabels: [(identifier: Int, name: String)] = {

		return self.orderedDataSetKeys.map {
			let identifier = self.globalIndexForKey($0)
			return (identifier: identifier, name: $0.name ?? "")
		}
	}()

	var isEmpty: Bool {
		return self.orderedDataSetKeys.count == 0
	}

	func globalIndexForKey(_ key: Any) -> Int {

		return self.globalKeySet.index(of: key)
	}

	var yValues: [[Double?]] {

		var yValues: [[Double]] = Array(repeating: [], count: self.xAxisLabels.count)

		for xIndex in 0..<self.xAxisLabels.count {

			for maybeY in self.sortedYValues(at: xIndex) {

				let y = maybeY ?? 0.0
				yValues[xIndex].append(y)
			}
		}
		return yValues
	}
}
