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

extension NSKeyValueChange: OptionalRawValueRepresentable {

}

class KanbanViewModel: NSObject, MVVMViewModel {

	enum ViewActions {

		case refreshTaskStates
		case addTasksAtIndexes(IndexSet)
		case deleteTasksAtIndexes(IndexSet)
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

	private var lastAdded = IndexSet()
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if context == &kTaskStatesContext {

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
				action = .refreshTaskStates
			}


			self.numTaskStates.value = self.project.taskStates?.count ?? 0
			self.viewActions.value = action ?? .refreshTaskStates
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

	func deleteTask(at index: Int) {

		self.project.removeFromTaskStates(at: index)
	}

	func taskStateViewModel(for index: Int) -> KanbanTaskStateItemViewModel? {

		guard let taskState = self.project.taskStates?[index] as? TaskState else {
			return nil
		}
		let viewModel = KanbanTaskStateItemViewModel(with: taskState)
		viewModel.editable.value = self.lastAdded.contains(index)
		return viewModel
	}
}
