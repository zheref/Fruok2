//
//  TaskState+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 09.08.17.
//
//

import Foundation
import CoreData


extension TaskState {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskState> {
        return NSFetchRequest<TaskState>(entityName: "TaskState");
    }

    @NSManaged public var name: String?
    @NSManaged public var tasks: Task?
    @NSManaged public var project: Project?

}
