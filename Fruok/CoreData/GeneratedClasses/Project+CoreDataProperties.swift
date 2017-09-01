//
//  Project+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 01.09.17.
//
//

import Foundation
import CoreData


extension Project {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: "Project");
    }

    @NSManaged public var codeName: String?
    @NSManaged public var commercialName: String?
    @NSManaged public var deadLine: NSDate?
    @NSManaged public var duration: Int32
    @NSManaged public var kind: Int32
    @NSManaged public var taskStates: NSOrderedSet?
    @NSManaged public var client: Client?

}

// MARK: Generated accessors for taskStates
extension Project {

    @objc(insertObject:inTaskStatesAtIndex:)
    @NSManaged public func insertIntoTaskStates(_ value: TaskState, at idx: Int)

    @objc(removeObjectFromTaskStatesAtIndex:)
    @NSManaged public func removeFromTaskStates(at idx: Int)

    @objc(insertTaskStates:atIndexes:)
    @NSManaged public func insertIntoTaskStates(_ values: [TaskState], at indexes: NSIndexSet)

    @objc(removeTaskStatesAtIndexes:)
    @NSManaged public func removeFromTaskStates(at indexes: NSIndexSet)

    @objc(replaceObjectInTaskStatesAtIndex:withObject:)
    @NSManaged public func replaceTaskStates(at idx: Int, with value: TaskState)

    @objc(replaceTaskStatesAtIndexes:withTaskStates:)
    @NSManaged public func replaceTaskStates(at indexes: NSIndexSet, with values: [TaskState])

    @objc(addTaskStatesObject:)
    @NSManaged public func addToTaskStates(_ value: TaskState)

    @objc(removeTaskStatesObject:)
    @NSManaged public func removeFromTaskStates(_ value: TaskState)

    @objc(addTaskStates:)
    @NSManaged public func addToTaskStates(_ values: NSOrderedSet)

    @objc(removeTaskStates:)
    @NSManaged public func removeFromTaskStates(_ values: NSOrderedSet)

}
