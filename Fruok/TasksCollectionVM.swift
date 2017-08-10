//
//  TasksCollectionVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond

class TasksCollectionViewModel: NSObject, MVVMViewModel {

	enum ViewActions {

		case refreshTasks
		case addTasksAtIndexes(IndexSet)
		case deleteTasksAtIndexes(IndexSet)
	}

	typealias MODEL = TaskState
	@objc dynamic private let taskState: TaskState
	required init(with model: TaskState) {

		self.taskState = model
		super.init()

		self.addObserver(self, forKeyPath: #keyPath(TasksCollectionViewModel.taskState.tasks), options: .initial, context: &kTasksContext)

	}

	deinit {
		self.removeObserver(self, forKeyPath: #keyPath(TasksCollectionViewModel.taskState.tasks))
	}

	private var kTasksContext = "kTasksContext"

	private var lastAdded = IndexSet()
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if context == &kTasksContext {

			var action: ViewActions? = nil
			switch NSKeyValueChange(optionalRawValue: change?[.kindKey] as? UInt) {

			case .insertion?:
				if let indexSet = change?[.indexesKey] as? IndexSet {
					action = .addTasksAtIndexes(indexSet)
					self.lastAdded = indexSet
				}
			case .removal?:
				if let indexSet = change?[.indexesKey] as? IndexSet {
					action = .deleteTasksAtIndexes(indexSet)
				}
				self.lastAdded = IndexSet()
			default:
				self.lastAdded = IndexSet()
				action = .refreshTasks
			}


			self.numTaskStates.value = self.taskState.tasks?.count ?? 0
			self.viewActions.value = action ?? .refreshTasks
		}
	}

	let numTaskStates = Observable<Int>(0)
	let viewActions = Observable<ViewActions?>(nil)

	func taskItemViewModel(for index: Int) -> KanbanTaskItemViewModel? {

		guard let task = self.taskState.tasks?[index] as? Task else {
			return nil
		}
		let viewModel = KanbanTaskItemViewModel(with: task)
		return viewModel
	}
}
