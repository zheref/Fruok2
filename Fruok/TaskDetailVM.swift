//
//  TaskDetailVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond
class TaskDetailViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Task
	@objc /*private*/ let task: Task
	required init(with model: Task) {
		self.task = model
		super.init()

		self.reactive.keyPath(#keyPath(TaskDetailViewModel.task.name), ofType: Optional<String>.self, context: .immediateOnMain).bind(to: self.name)
			.dispose(in: bag)

		self.reactive.keyPath(#keyPath(TaskDetailViewModel.task.descriptionString), ofType: Optional<NSAttributedString>.self, context: .immediateOnMain)
			.bind(to: self.descriptionText)
		.dispose(in: bag)
	}

	let name = Observable<String?>("")
	let descriptionText = Observable<NSAttributedString?>(NSAttributedString(string:""))
	let dismiss = Observable<Bool>(false)

	struct TaskDeleteConfirmationInfo {
		let question: String
		let callback: () -> Void
	}

	let taskDeleteConfirmation = Observable<TaskDeleteConfirmationInfo?>(nil)

	func userRequestsTaskDeletion() {

		let thisTask = self.task

		let info = TaskDeleteConfirmationInfo(
			question:

			NSString(format: NSLocalizedString("Delete task %@?", comment: "Task deletion") as NSString, self.task.name ?? "") as String,
			callback: { [weak self] in

				self?.dismiss.value = true
				let project = thisTask.state?.project
				project?.managedObjectContext?.undoManager?.beginUndoGrouping()
				defer { project?.managedObjectContext?.undoManager?.endUndoGrouping() }
				thisTask.state?.removeFromTasks(thisTask)
				thisTask.managedObjectContext?.delete(thisTask)
				project?.purgeUnusedLabels()
				self?.dismiss.value = true
		})

		self.taskDeleteConfirmation.value = info
	}

	func subtasksViewModel() -> SubtasksViewModel {

		return SubtasksViewModel(with: self.task)
	}

	func labelsViewModel() -> LabelsViewModel {

		return LabelsViewModel(with: self.task)
	}

	func userWantsChangeDescriptionText(attributedString: NSAttributedString) {
		self.task.descriptionString = attributedString
	}
	func userWantsChangeName(name: String) {
		self.task.name = name
	}

}
