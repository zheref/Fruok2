//
//  Attachment+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 07.09.17.
//
//

import Foundation
import CoreData


extension Attachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment");
    }

    @NSManaged public var filename: String
    @NSManaged public var identifier: String
    @NSManaged public var project: Project?
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for tasks
extension Attachment {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}
