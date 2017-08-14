//
//  CollectionViewModel.swift
//  Fruok
//
//  Created by Matthias Keiser on 13.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

enum CollectionViewModelActions {

	case refreshTaskStates
	case addTasksAtIndexes(IndexSet)
	case deleteTasksAtIndexes(IndexSet)
	case moveTasks([Int: Int])
}

protocol CollectionViewModel: class, MVVMViewModel {

	var model: MODEL {get}
	var modelCollectionKeyPath: String {get} // keypath relativ to model
	var supressTaskStateObservation: Bool {get set}
	func objectIndexes(for uriStrings: [String]) -> IndexSet

	var numCollectionObjects: Property<Int> {get}
	var viewActions: Property<CollectionViewModelActions?> {get}
}

protocol CollectionDragAndDropViewModel: CollectionViewModel {

	func pasteboardItemForTastState(at index: Int) -> NSPasteboardWriting?
	func dropIndex(forDraggedURIs uriStrings: [String], proposedIndex proposed: Int) -> [String: Int]?
	static func actualDropIndex(forDraggedIndexes draggedIndexes: IndexSet, proposedIndex proposed: Int, withNumStates numStates: Int) -> Int
	func moveObjects(withURIStrings uriStrings: [String], beforeIndexPath: IndexPath) -> Bool
}

extension CollectionViewModel where Self.MODEL: NSManagedObject {

	func objectIndexes(for uriStrings: [String]) -> IndexSet {

		let modelObjects = self.model.mutableOrderedSetValue(forKeyPath: self.modelCollectionKeyPath)

		let objectIndexes: IndexSet = self.objects(for: uriStrings).map {
				modelObjects.index(of: $0)
			}.filter{
				$0 != NSNotFound
			}.reduce(IndexSet()) { (result, index) -> IndexSet in
				var resultCopy = result
				resultCopy.insert(index)
				return resultCopy
		}
		return objectIndexes
	}

	func objects(for uriStrings: [String]) -> [NSManagedObject] {

		return uriStrings.flatMap {
			self.model.managedObjectContext?.object(withURIString: $0)
		}
	}

	func reactToCoreDataKVOMessage(_ change: [NSKeyValueChangeKey : Any]?) {

		if !self.supressTaskStateObservation {

			var action: CollectionViewModelActions? = nil
			switch NSKeyValueChange(optionalRawValue: change?[.kindKey] as? UInt) {

			case .insertion?:
				if let indexSet = change?[.indexesKey] as? IndexSet {
					action = .addTasksAtIndexes(indexSet)
				}
			case .removal?:
				if let indexSet = change?[.indexesKey] as? IndexSet {
					action = .deleteTasksAtIndexes(indexSet)
				}
			default:
				action = .refreshTaskStates
			}


			self.numCollectionObjects.value = self.model.mutableOrderedSetValue(forKeyPath: self.modelCollectionKeyPath).count
			self.viewActions.value = action ?? .refreshTaskStates
		}
	}
}

extension CollectionDragAndDropViewModel where Self.MODEL: NSManagedObject {

	func moveObjects(withURIStrings uriStrings: [String], beforeIndexPath: IndexPath) -> Bool {

		guard let (localObjects, localObjectIndexes, foreignObjects) = self.objectsInfo(forURIs: uriStrings) else {
			return false
		}

		guard (localObjects.count + foreignObjects.count) == uriStrings.count else {
			return false
		}

		guard let dropIndexes = self.dropIndex(forDraggedURIs: uriStrings, proposedIndex: beforeIndexPath.item) else {
			return false
		}

		let localDropIndexes = dropIndexes.filter { (uri, index) -> Bool in

			return localObjects[uri] != nil
			}.reduce(Dictionary<String, Int>()) { (dict, pair: (key: String, value: Int)) in

				var copy = dict
				copy[pair.key] = pair.value
				return copy
		}

		let modelObjects = self.model.mutableOrderedSetValue(forKeyPath: self.modelCollectionKeyPath)

		if let smallesLocalIndex = localDropIndexes.map ({ key, index in return index }).sorted().first {

			var mappingDict = Dictionary<Int, Int>()
			for (key, localObject) in localObjects {

				mappingDict[modelObjects.index(of: localObject)] = localDropIndexes[key]!
			}

			self.supressTaskStateObservation = true
			modelObjects.moveObjects(at: localObjectIndexes, to: smallesLocalIndex)

			self.viewActions.value = .moveTasks(mappingDict)
			self.supressTaskStateObservation = false
		}

		for (key, foreignObject) in foreignObjects {

			modelObjects.insert(foreignObject, at: dropIndexes[key]!)
		}
		return true
	}

	private func objectsInfo(forURIs uriStrings: [String]) -> ([String: AnyObject], IndexSet, [String: AnyObject])? {

		let modelObjects = self.model.mutableOrderedSetValue(forKeyPath: self.modelCollectionKeyPath)

		let draggedObjects = self.objects(for: uriStrings)

		guard draggedObjects.count == uriStrings.count else {
			return nil
		}

		var localObjects: [String: AnyObject] = [:]
		var localObjectIndexes = IndexSet()
		var foreignObjects: [String: AnyObject] = [:]

		for (object, uri) in zip(draggedObjects, uriStrings) {

			if modelObjects.contains(object) {
				localObjects[uri] = object
				localObjectIndexes.insert(modelObjects.index(of: object))
			} else {
				foreignObjects[uri] = object
			}
		}

		return (localObjects, localObjectIndexes, foreignObjects)
	}

	func dropIndex(forDraggedURIs uriStrings: [String], proposedIndex proposed: Int) -> [String: Int]? {

		let modelObjects = self.model.mutableOrderedSetValue(forKeyPath: self.modelCollectionKeyPath)

		let draggedObjects = self.objects(for: uriStrings)

		guard draggedObjects.count == uriStrings.count else {
			return nil
		}

		guard let (localObjects, localObjectIndexes, foreignObjects) = self.objectsInfo(forURIs: uriStrings) else {
			return nil
		}

		var dropIndex = proposed - localObjectIndexes.filteredIndexSet(includeInteger: {$0 < proposed}).count
		dropIndex = dropIndex >= modelObjects.count ? (modelObjects.count - 1) : dropIndex

		var result: [String: Int] = [:]

		for uri in uriStrings {

			if localObjects[uri] != nil {
				result[uri] = dropIndex
				dropIndex += 1
			}
		}
		for uri in uriStrings {

			if foreignObjects[uri] != nil {
				result[uri] = dropIndex + 1
				dropIndex += 1
			}
		}

		return result
	}

	static func actualDropIndex(forDraggedIndexes draggedIndexes: IndexSet, proposedIndex proposed: Int, withNumStates numStates: Int) -> Int {

		let dropIndexAfter = proposed - draggedIndexes.filteredIndexSet(includeInteger: {$0 < proposed}).count

		return dropIndexAfter >= numStates ? (numStates - 1) : dropIndexAfter
	}
}
