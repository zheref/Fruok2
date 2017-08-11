//
//  KanbanTaskItemVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond

class KanbanTaskItemViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Task
	@objc private let task: Task

	required init(with model: MODEL) {
		self.task = model
		super.init()

		self.reactive.keyPath(#keyPath(KanbanTaskItemViewModel.task.name), ofType: Optional<String>.self, context: .immediateOnMain)
			.bidirectionalBind(to: self.taskName)
		.dispose(in: bag)

		self.reactive.keyPath(#keyPath(KanbanTaskItemViewModel.task.descriptionString.string), ofType: Optional<String>.self, context: .immediateOnMain).bind(to: self.taskDescription)
			.dispose(in: bag)

	}

	func userRequestedTaskDetails() {

		self.showTaskDetails.value = true
	}
	
	func viewModelForTaskDetail() -> TaskDetailViewModel {
		let viewModel = TaskDetailViewModel(with: self.task)
		return viewModel
	}

	let taskName = Observable<String?>("")
	let taskDescription = Observable<String?>("")
	let showTaskDetails = Observable<Bool>(false)
}
