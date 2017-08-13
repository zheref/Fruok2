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
		case moveTasks([Int: Int])
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

		if context == &kTaskStatesContext && !self.supressTaskStateObservation {

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
			let state: TaskState = NSEntityDescription.insertNewObject(forEntityName: TaskState.entityName, into: context) as! TaskState
			state.name = NSLocalizedString("Untitled", comment: "Untitled tasks tate")
			self.project.addToTaskStates(state)
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
		self.lastAdded.remove(index)
		return viewModel
	}

	func pasteboardItemForTastState(at index: Int) -> NSPasteboardWriting? {

		return self.project.taskStates?[index] as? TaskState
	}

	var supressTaskStateObservation = false

	func moveTaskStates(withURIStrings uriStrings: [String], beforeIndexPath: IndexPath) -> Bool {

		let objectIndexes = self.objectIndexes(for: uriStrings)

		guard objectIndexes.count == uriStrings.count else {
			return false
		}

		let taskStates = self.project.mutableOrderedSetValue(forKey: #keyPath(Project.taskStates))

		self.supressTaskStateObservation = true
		let targetIndex = KanbanViewModel.actualDropIndex(forDraggedIndexes: objectIndexes, proposedIndex: beforeIndexPath.item, withNumStates: taskStates.count)
			taskStates.moveObjects(at: objectIndexes, to: targetIndex)
		let mappingDict: Dictionary<Int, Int> = zip(objectIndexes, 0..<objectIndexes.count)
			.reduce(Dictionary<Int, Int>()) { (result, pair)  in

				var copy = result
				copy[pair.0] = pair.1 + targetIndex
				return copy
		}

		self.viewActions.value = .moveTasks(mappingDict)
		self.supressTaskStateObservation = false

		return true
	}

	func objectIndexes(for uriStrings: [String]) -> IndexSet {

		let taskStates = self.project.mutableOrderedSetValue(forKey: #keyPath(Project.taskStates))

		let objectIndexes: IndexSet = uriStrings.flatMap { self.project.managedObjectContext?.object(withURIString: $0) }
			.flatMap { $0 as? TaskState }
			.map { taskStates.index(of: $0) }
			.filter{ $0 != NSNotFound }
			.reduce(IndexSet()) { (result, index) -> IndexSet in
				var resultCopy = result
				resultCopy.insert(index)
				return resultCopy
		}
		return objectIndexes
	}

	static func actualDropIndex(forDraggedIndexes draggedIndexes: IndexSet, proposedIndex proposed: Int, withNumStates numStates: Int) -> Int {

		let dropIndexAfter = proposed - draggedIndexes.filteredIndexSet(includeInteger: {$0 < proposed}).count

		return dropIndexAfter >= numStates ? (numStates - 1) : dropIndexAfter
	}
}
