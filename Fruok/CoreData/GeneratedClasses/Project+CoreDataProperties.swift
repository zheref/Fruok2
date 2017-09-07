//
//  Project+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 07.09.17.
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
    @NSManaged public var currency: String?
    @NSManaged public var deadLine: NSDate?
    @NSManaged public var duration: Int32
    @NSManaged public var fee: NSDecimalNumber?
    @NSManaged public var kind: Int32
    @NSManaged public var tax: NSDecimalNumber?
    @NSManaged public var taxName: String?
    @NSManaged public var attachments: NSOrderedSet?
    @NSManaged public var client: Client?
    @NSManaged public var developer: Developer?
    @NSManaged public var taskStates: NSOrderedSet?

}

// MARK: Generated accessors for attachments
extension Project {

    @objc(insertObject:inAttachmentsAtIndex:)
    @NSManaged public func insertIntoAttachments(_ value: Attachment, at idx: Int)

    @objc(removeObjectFromAttachmentsAtIndex:)
    @NSManaged public func removeFromAttachments(at idx: Int)

    @objc(insertAttachments:atIndexes:)
    @NSManaged public func insertIntoAttachments(_ values: [Attachment], at indexes: NSIndexSet)

    @objc(removeAttachmentsAtIndexes:)
    @NSManaged public func removeFromAttachments(at indexes: NSIndexSet)

    @objc(replaceObjectInAttachmentsAtIndex:withObject:)
    @NSManaged public func replaceAttachments(at idx: Int, with value: Attachment)

    @objc(replaceAttachmentsAtIndexes:withAttachments:)
    @NSManaged public func replaceAttachments(at indexes: NSIndexSet, with values: [Attachment])

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachment)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachment)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSOrderedSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSOrderedSet)

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
