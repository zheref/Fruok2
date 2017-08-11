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

		self.reactive.keyPath(#keyPath(TaskDetailViewModel.task.name), ofType: Optional<String>.self, context: .immediateOnMain).bidirectionalBind(to: self.name)
			.dispose(in: bag)

		self.reactive.keyPath(#keyPath(TaskDetailViewModel.task.descriptionString), ofType: Optional<NSAttributedString>.self, context: .immediateOnMain)
			.bidirectionalBind(to: self.descriptionText)
		.dispose(in: bag)

		self.reactive.keyPath(#keyPath(TaskDetailViewModel.task.state.name), ofType: Optional<String>.self, context: .immediateOnMain)
			.bidirectionalBind(to: self.stateName)
			.dispose(in: bag)

	}

	let name = Observable<String?>("")
	let stateName = Observable<String?>("")
	let descriptionText = Observable<NSAttributedString?>(NSAttributedString(string:""))

}
