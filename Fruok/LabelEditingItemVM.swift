//
//  LabelEditingVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 19.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond

class LabelEditingItemViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Task
	@objc private let task: Task

	convenience init(with model: Task, initialEditingString: String) {
		self.init(with: model)
		self.initialEditingString.value = initialEditingString
	}

	required init(with model: Task) {

		self.task = model
		super.init()
		
		self.currentEditingString.observeNext { [weak self] editingString in

			self?.updateCurrentEditingSuggestions()

		}.dispose(in: bag)

		self.currentEditingSuggestionLabels.flatMap {
			($0.name, $0.color != nil ? $0.color!.rgbaColorValues : RGBAColorValues.defaultLabelColor)
		}.bind(to: self.currentEditingSuggestions).dispose(in: bag)
	}

	func updateCurrentEditingSuggestions() {

		let taskLabels: Set<Label> = self.task.labels?.array as? [Label] != nil ? Set<Label>(self.task.labels!.array as! [Label]) : Set<Label>()

		let labelSet: Set<Label> = (self.task.state?.project?.labels ?? Set()).subtracting(taskLabels)

		let filteredLabels: [Label]

		if let editingString = self.currentEditingString.value, editingString.isEmpty { // Empty string

			filteredLabels = Array(labelSet)

		} else if let editingString = self.currentEditingString.value { // Any String

			let predicate = NSPredicate(format: "self BEGINSWITH[cd] %@", argumentArray: [editingString])
			filteredLabels = labelSet.filter { predicate.evaluate(with: $0.name) }

		} else { // Nil String
			filteredLabels = Array(labelSet)
		}

		self.currentEditingSuggestionLabels.value = filteredLabels.sorted(by: {
			($0.name).caseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending
		})
	}

	let initialEditingString = Property<String>("")
	let currentEditingString = Property<String?>(nil)
	let currentEditingSuggestionLabels = Property<[Label]>([])
	let currentEditingSuggestions = Property<[(name: String, color: RGBAColorValues)]>([])
	let labelColor = Property<RGBAColorValues>(RGBAColorValues.defaultLabelColor)

	var existingLabel: Label? = nil

	func userSelectedExistingLabel(atCurrentSuggestionsIndex suggestionIndex: Int) {

		self.existingLabel = self.currentEditingSuggestionLabels.value[suggestionIndex]
	}

}
