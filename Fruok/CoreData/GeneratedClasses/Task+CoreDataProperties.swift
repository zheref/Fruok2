//
//  Task+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 19.08.17.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task");
    }

    @NSManaged public var state: TaskState?
    @NSManaged public var subtasks: NSOrderedSet?
    @NSManaged public var labels: NSOrderedSet?

}

// MARK: Generated accessors for subtasks
extension Task {

    @objc(insertObject:inSubtasksAtIndex:)
    @NSManaged public func insertIntoSubtasks(_ value: Subtask, at idx: Int)

    @objc(removeObjectFromSubtasksAtIndex:)
    @NSManaged public func removeFromSubtasks(at idx: Int)

    @objc(insertSubtasks:atIndexes:)
    @NSManaged public func insertIntoSubtasks(_ values: [Subtask], at indexes: NSIndexSet)

    @objc(removeSubtasksAtIndexes:)
    @NSManaged public func removeFromSubtasks(at indexes: NSIndexSet)

    @objc(replaceObjectInSubtasksAtIndex:withObject:)
    @NSManaged public func replaceSubtasks(at idx: Int, with value: Subtask)

    @objc(replaceSubtasksAtIndexes:withSubtasks:)
    @NSManaged public func replaceSubtasks(at indexes: NSIndexSet, with values: [Subtask])

    @objc(addSubtasksObject:)
    @NSManaged public func addToSubtasks(_ value: Subtask)

    @objc(removeSubtasksObject:)
    @NSManaged public func removeFromSubtasks(_ value: Subtask)

    @objc(addSubtasks:)
    @NSManaged public func addToSubtasks(_ values: NSOrderedSet)

    @objc(removeSubtasks:)
    @NSManaged public func removeFromSubtasks(_ values: NSOrderedSet)

}

// MARK: Generated accessors for labels
extension Task {

    @objc(insertObject:inLabelsAtIndex:)
    @NSManaged public func insertIntoLabels(_ value: Label, at idx: Int)

    @objc(removeObjectFromLabelsAtIndex:)
    @NSManaged public func removeFromLabels(at idx: Int)

    @objc(insertLabels:atIndexes:)
    @NSManaged public func insertIntoLabels(_ values: [Label], at indexes: NSIndexSet)

    @objc(removeLabelsAtIndexes:)
    @NSManaged public func removeFromLabels(at indexes: NSIndexSet)

    @objc(replaceObjectInLabelsAtIndex:withObject:)
    @NSManaged public func replaceLabels(at idx: Int, with value: Label)

    @objc(replaceLabelsAtIndexes:withLabels:)
    @NSManaged public func replaceLabels(at indexes: NSIndexSet, with values: [Label])

    @objc(addLabelsObject:)
    @NSManaged public func addToLabels(_ value: Label)

    @objc(removeLabelsObject:)
    @NSManaged public func removeFromLabels(_ value: Label)

    @objc(addLabels:)
    @NSManaged public func addToLabels(_ values: NSOrderedSet)

    @objc(removeLabels:)
    @NSManaged public func removeFromLabels(_ values: NSOrderedSet)

}
