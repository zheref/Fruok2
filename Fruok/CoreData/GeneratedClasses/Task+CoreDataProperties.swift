//
//  Task+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 06.09.17.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task");
    }

    @NSManaged public var attachments: NSOrderedSet?
    @NSManaged public var labels: NSOrderedSet?
    @NSManaged public var pomodoroSessions: NSSet?
    @NSManaged public var state: TaskState?
    @NSManaged public var subtasks: NSOrderedSet?

}

// MARK: Generated accessors for attachments
extension Task {

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

// MARK: Generated accessors for pomodoroSessions
extension Task {

    @objc(addPomodoroSessionsObject:)
    @NSManaged public func addToPomodoroSessions(_ value: PomodoroSession)

    @objc(removePomodoroSessionsObject:)
    @NSManaged public func removeFromPomodoroSessions(_ value: PomodoroSession)

    @objc(addPomodoroSessions:)
    @NSManaged public func addToPomodoroSessions(_ values: NSSet)

    @objc(removePomodoroSessions:)
    @NSManaged public func removeFromPomodoroSessions(_ values: NSSet)

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
