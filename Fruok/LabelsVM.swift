//
//  LabelsVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 18.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

class LabelsViewModel: NSObject, CollectionDragAndDropViewModel {

	typealias MODEL = Task
	@objc private let task: Task

	private var kLabelsContext = "kLabelsContext"

	required init(with model: MODEL) {

		self.task = model
		super.init()

		self.addObserver(self, forKeyPath: #keyPath(LabelsViewModel.task.labels), options: .initial, context: &kLabelsContext)
	}

	deinit {
		self.removeObserver(self, forKeyPath: #keyPath(LabelsViewModel.task.labels))
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if context == &kLabelsContext {
			self.reactToCoreDataKVOMessage(change)
		}
	}

	var model: MODEL {
		return self.task
	}

	var modelCollectionKeyPath = #keyPath(Task.labels)
	var supressTaskStateObservation = false

	let numCollectionObjects = Property<Int>(0)
	let viewActions = Property<CollectionViewModelActions?>(nil)

	func pasteboardItemForTastState(at index: Int) -> NSPasteboardWriting? {
		return "__none__" as NSString
	}

	let indexBeingEdited = Property<Int?>(nil)

	var numItemsIncludingEditing: Int {

		guard let editedIndex = self.indexBeingEdited.value else {
			return self.numCollectionObjects.value
		}

		if editedIndex < self.numCollectionObjects.value {
			return self.numCollectionObjects.value
		}
		else if editedIndex == self.numCollectionObjects.value {
			return self.numCollectionObjects.value + 1
		}

		preconditionFailure()
	}

	func labelItemViewModel(for index: Int) -> LabelViewModelType? {

		if index == self.indexBeingEdited.value {

			return LabelEditingItemViewModel(with: self.task)
		}

		guard let label = self.task.labels?[index] as? Label else {
			return nil
		}
		let viewModel = LabelItemViewModel(with: label)

		return viewModel
	}

	func userWantsAddLabel() {

		if self.indexBeingEdited.value == self.numCollectionObjects.value {
			return
		}

		if self.indexBeingEdited.value != nil {
			self.userWantsCancelEditLabel()
		}
		
		self.indexBeingEdited.value = self.numCollectionObjects.value
		
		self.viewActions.value = .addTasksAtIndexes(IndexSet(integer: self.numCollectionObjects.value))
	}

	func userWantsEditLabel(at index: Int) {

		self.indexBeingEdited.value = index
		self.viewActions.value = .refreshTaskStates
	}

	func userWantsCancelEditLabel() {

		self.indexBeingEdited.value = nil
		self.viewActions.value = .refreshTaskStates
	}

	func userWantsCommitEditLabel(with viewModel: LabelEditingItemViewModel) {

		self.task.managedObjectContext?.undoGroupWithOperations({ context in

			guard let editingIndex = self.indexBeingEdited.value, let labels = self.task.labels else {
				return
			}

			let label: Label
			if editingIndex < self.numCollectionObjects.value {

				label = labels[editingIndex] as! Label
			} else {

				label = context.insertObject()
			}

			label.name = viewModel.currentEditingString.value ?? NSLocalizedString("Untitled", comment: "Untitled Label")

			let color: LabelColor = label.color ?? {

				let color = context.insertObject() as LabelColor
				label.color = color
				return color
				}()

			color.rgbaColorValues = viewModel.labelColor.value

			self.indexBeingEdited.value = nil
			self.supressTaskStateObservation = true
			self.task.insertIntoLabels(label, at: editingIndex)
			self.numCollectionObjects.value = self.task.labels?.count ?? 0
			self.supressTaskStateObservation = false
			self.viewActions.value = .refreshTaskStates
		})
	}

	func userWantsDeleteLabel(at index: Int) {

		guard let label = self.task.labels?[index] as? Label else {
			return
		}

		label.managedObjectContext?.undoGroupWithOperations({ context in

			let project = self.task.state?.project
			self.task.removeFromLabels(label)
			project?.purgeUnusedLabels()
		})
	}

	func userWantsSetExisintLabelAtEditingPosition(editViewModel: LabelEditingItemViewModel) {

		guard let label = editViewModel.existingLabel, let editingIndex = self.indexBeingEdited.value else {
			return
		}

		label.managedObjectContext?.undoGroupWithOperations({ context in

			self.indexBeingEdited.value = nil
			self.supressTaskStateObservation = true
			self.task.insertIntoLabels(label, at: editingIndex)
			self.numCollectionObjects.value = self.task.labels?.count ?? 0
			self.supressTaskStateObservation = false
			self.viewActions.value = .refreshTaskStates
		})
	}
}

protocol LabelViewModelType {
}

extension LabelItemViewModel: LabelViewModelType {
}
extension LabelEditingItemViewModel: LabelViewModelType{
}
