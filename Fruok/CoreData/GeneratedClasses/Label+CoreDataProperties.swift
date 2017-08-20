//
//  Label+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 19.08.17.
//
//

import Foundation
import CoreData


extension Label {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Label> {
        return NSFetchRequest<Label>(entityName: "Label");
    }

    @NSManaged public var name: String
    @NSManaged public var color: LabelColor?
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for tasks
extension Label {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}
