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
		self.addObserver(self, forKeyPath: #keyPath(KanbanTaskStateItemViewModel.taskState.name), options: .initial, context: &nameContext)
		self.addObserver(self, forKeyPath: #keyPath(KanbanTaskStateItemViewModel.taskState.tasks), options: .initial, context: &tasksContext)
	}

	deinit {
		self.removeObserver(self, forKeyPath: #keyPath(KanbanTaskStateItemViewModel.taskState.name))
		self.removeObserver(self, forKeyPath: #keyPath(KanbanTaskStateItemViewModel.taskState.tasks))
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if context == &nameContext {

			self.name.value = self.taskState.name
		} else if context == &tasksContext {

		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}

	let name = Observable<String?>(nil)
}
