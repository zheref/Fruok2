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

class KanbanViewModel: NSObject, CollectionDragAndDropViewModel {

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

			self.reactToCoreDataKVOMessage(change)
		}
	}

	let modelCollectionKeyPath = #keyPath(Project.taskStates) // keypath relativ to model
	var model: MODEL {
		return self.project
	}
	let numCollectionObjects = Observable<Int>(0)
	let viewActions = Observable<CollectionViewModelActions?>(nil)

	var lastAddedIndex: Int?

	func addTask() {

		if let context = self.project.managedObjectContext {
			let state: TaskState = NSEntityDescription.insertNewObject(forEntityName: TaskState.entityName, into: context) as! TaskState
			state.name = NSLocalizedString("Untitled", comment: "Untitled tasks tate")
			self.lastAddedIndex = self.project.taskStates?.count
			self.project.addToTaskStates(state)
		}
	}

	func deleteTaskState(at index: Int) {

		self.project.removeFromTaskStates(at: index)
	}

	func taskStateViewModel(for index: Int) -> KanbanTaskStateItemViewModel? {

		guard let taskState = self.project.taskStates?[index] as? TaskState else {
			return nil
		}
		let viewModel = KanbanTaskStateItemViewModel(with: taskState)
		if self.lastAddedIndex == index {
			viewModel.editable.value = true
			self.lastAddedIndex = nil
		}
		return viewModel
	}

	func pasteboardItemForTastState(at index: Int) -> NSPasteboardWriting? {

		return self.project.taskStates?[index] as? TaskState
	}

	var supressTaskStateObservation = false
}
