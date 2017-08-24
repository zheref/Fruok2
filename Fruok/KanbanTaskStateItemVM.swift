//
//  KanbanTaskStateItemVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 09.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import Bond

class KanbanTaskStateItemViewModel: NSObject, MVVMViewModel {

	typealias MODEL = TaskState
	@objc dynamic private let taskState: TaskState

	private var nameContext = "nameContext"
	private var tasksContext = "tasksContext"

	required init(with model: TaskState) {
		self.taskState = model
		super.init()
		self.reactive.keyPath(#keyPath(KanbanTaskStateItemViewModel.taskState.name), ofType: Optional<String>.self, context: .immediateOnMain).bind(to: self.name).dispose(in: bag)
	}

	let name = Observable<String?>(nil)
	let editable = Observable<Bool>(false)

	func userDidChangeName(to name: String) {

		self.taskState.name = name
		self.editable.value = false
	}

	func userWantsAddTask() {

		self.taskState.managedObjectContext?.undoGroupWithOperations({ context in

			let task: Task = context.insertObject()
			self.taskState.addToTasks(task)

			NotificationCenter.default.post(name: .FRUDisplayDetailRequestedForTask, object: self.taskState, userInfo: [FRUDisplayDetailRequestedInfoKeys.task.rawValue: task])
		})
	}

	func tasksCollectionViewModel() -> TasksCollectionViewModel {

		return TasksCollectionViewModel(with: self.taskState)
	}

}
