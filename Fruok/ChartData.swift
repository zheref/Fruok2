//
//  ChartData.swift
//  Fruok
//
//  Created by Matthias Keiser on 30.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

class ChartData<XKey: Hashable, YKey: Hashable> {

	init(data: [XKey:[YKey: [PomodoroSession]]],
	     globalKeySet: NSOrderedSet,
	     xKeySorter: @escaping (XKey, XKey) -> Bool,
	     yKeySorter: @escaping (YKey, YKey) -> Bool,
	     xKeyLabelProvider: @escaping (XKey) -> String,
	     yKeyLabelProvider: @escaping (YKey) -> String ){

		self.data = data
		self.globalKeySet = globalKeySet
		self.xKeySorter = xKeySorter
		self.yKeySorter = yKeySorter
		self.xKeyLabelProvider = xKeyLabelProvider
		self.yKeyLabelProvider = yKeyLabelProvider
	}

	private let data: [XKey:[YKey: [PomodoroSession]]]
	private let globalKeySet: NSOrderedSet
	private let xKeySorter: (XKey, XKey) -> Bool
	private let yKeySorter: (YKey, YKey) -> Bool
	private let xKeyLabelProvider: (XKey) -> String
	private let yKeyLabelProvider: (YKey) -> String

	private var sortedXKeys: [XKey] {
		return self.data.keys.sorted(by: self.xKeySorter)
	}
	var xAxisLabels: [String] {

		return self.sortedXKeys.map { self.xKeyLabelProvider($0) }
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

	private lazy var orderedDataSetKeys: [YKey] = {

		var keys: Set<YKey> = []

		for dict in self.data.values {

			keys.formUnion(Set(dict.keys))
		}

		let sorted = keys.sorted(by: self.yKeySorter)

		return sorted
	}()

	lazy var dataSetLabels: [(identifier: Int, name: String)] = {

		return self.orderedDataSetKeys.map {
			let identifier = self.globalIndexForKey($0)
			return (identifier: identifier, name: self.yKeyLabelProvider($0))
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
