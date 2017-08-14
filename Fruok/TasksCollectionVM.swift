//
//  TasksCollectionVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond

class TasksCollectionViewModel: NSObject, CollectionDragAndDropViewModel {

	internal func pasteboardItemForTastState(at index: Int) -> NSPasteboardWriting? {

		return self.taskState.tasks?[index] as? Task
	}
	var model: MODEL {
		return self.taskState
	}
	let modelCollectionKeyPath = #keyPath(TaskState.tasks)
	var supressTaskStateObservation = false

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

			self.reactToCoreDataKVOMessage(change)
		}
	}

	let numCollectionObjects = Observable<Int>(0)
	let viewActions = Observable<CollectionViewModelActions?>(nil)

	func taskItemViewModel(for index: Int) -> KanbanTaskItemViewModel? {

		guard let task = self.taskState.tasks?[index] as? Task else {
			return nil
		}
		let viewModel = KanbanTaskItemViewModel(with: task)
		return viewModel
	}
}
