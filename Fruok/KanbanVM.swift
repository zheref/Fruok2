//
//  KanbanVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 08.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit
import Bond

class KanbanViewModel: NSObject, MVVMViewModel {

	enum ViewActions {

		case refreshTaskStates
	}

	typealias MODEL = Project
	@objc private let project: Project
	required init(with model: Project) {

		self.project = model
		super.init()
		self.addObserver(self, forKeyPath: #keyPath(KanbanViewModel.project.taskStates), options: .initial, context: &kTaskStatesContext)

	}

	deinit {
		self.removeObserver(self, forKeyPath: #keyPath(KanbanViewModel.project.taskStates))
	}
	
	private var kTaskStatesContext = "kTaskStatesContext"

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if context == &kTaskStatesContext {

			self.numTaskStates.value = self.project.taskStates?.count ?? 0
			self.viewActions.value = .refreshTaskStates
		}
	}

	let numTaskStates = Observable<Int>(0)
	let viewActions = Observable<ViewActions?>(nil)

	func addTask() {

		if let context = self.project.managedObjectContext {
			let state: TaskState = NSEntityDescription.insertNewObject(forEntityName: "TaskState", into: context) as! TaskState
			state.name = "kjjkj"
			self.project.addToTaskStates(state)
			NSEntityDescription.insertNewObject(forEntityName: "TaskState", into: context)
		}
	}
}
