//
//  SubtasksVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 16.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond

class SubtasksViewModel: NSObject, CollectionViewModel {

	typealias MODEL = Task
	@objc private let task: Task

	required init(with model: MODEL) {

		self.task = model
		super.init()

		self.addObserver(self, forKeyPath: #keyPath(SubtasksViewModel.task.subtasks), options: .initial, context: &kSubtasksContext)
	}

	deinit {
		self.removeObserver(self, forKeyPath: #keyPath(SubtasksViewModel.task.subtasks))
	}

	var model: Task {
		return self.task
	}
	let modelCollectionKeyPath = #keyPath(Task.subtasks)
	var supressTaskStateObservation = false
	
	let numCollectionObjects = Observable<Int>(0)
	let viewActions = Observable<CollectionViewModelActions?>(nil)


	private var kSubtasksContext = "kSubtasksContext"

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if context == &kSubtasksContext {

			self.reactToCoreDataKVOMessage(change)
		}
	}

	func reactToCoreDataKVOMessage(_ change: [NSKeyValueChangeKey : Any]?) {

		if !self.supressTaskStateObservation {

			var action: CollectionViewModelActions? = nil
			switch NSKeyValueChange(optionalRawValue: change?[.kindKey] as? UInt) {

			case .insertion?:
				if let indexSet = change?[.indexesKey] as? IndexSet {
					action = .addTasksAtIndexes(indexSet)
				}
			case .removal?:
				if let indexSet = change?[.indexesKey] as? IndexSet {
					action = .deleteTasksAtIndexes(indexSet)
				}
			default:
				action = .refreshTaskStates
			}


			self.numCollectionObjects.value = self.model.mutableOrderedSetValue(forKeyPath: self.modelCollectionKeyPath).count + 1
			self.viewActions.value = action ?? .refreshTaskStates
		}
	}


	var editableIndex: Int?
	var addButtonIndex: Int? {
		return self.task.subtasks?.count ?? 0
	}

	func userWantsAddSubtask() {

		self.task.managedObjectContext?.undoGroupWithOperations({ context in

			let subtask: Subtask = context.insertObject() as Subtask
			subtask.name = NSLocalizedString("Untitled", comment: "Untitled Subtask")
			self.editableIndex = self.task.subtasks?.count
			self.task.addToSubtasks(subtask)
		})
	}

	func userWantsEditSubtask(at index: Int) {

		self.editableIndex = index
		self.viewActions.value = .refreshTaskStates
	}

	func userWantsDeleteSubtask(at index: Int) {

		self.task.managedObjectContext?.undoGroupWithOperations({ context in

			guard let subtask = self.task.subtasks?[index] as? Subtask else { return }
			self.task.removeFromSubtasks(subtask)
			context.delete(subtask)
		})
	}

	func userWantsCancelEdit() {
		
		self.editableIndex = nil
		self.viewActions.value = .refreshTaskStates
	}

	func subtaskViewModel(for index: Int) -> SubtaskViewModel {

		let viewModel = SubtaskViewModel(with: self.task.subtasks![index] as! Subtask)
		if index == self.editableIndex {
			viewModel.editable.value = true
		}
		return viewModel
	}
}
