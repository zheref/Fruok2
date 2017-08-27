//
//  Subtask+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 27.08.17.
//
//

import Foundation
import CoreData


extension Subtask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subtask> {
        return NSFetchRequest<Subtask>(entityName: "Subtask");
    }

    @NSManaged public var done: Bool
    @NSManaged public var task: Task?
    @NSManaged public var pomodoroLogs: NSSet?

}

// MARK: Generated accessors for pomodoroLogs
extension Subtask {

    @objc(addPomodoroLogsObject:)
    @NSManaged public func addToPomodoroLogs(_ value: PomodoroLog)

    @objc(removePomodoroLogsObject:)
    @NSManaged public func removeFromPomodoroLogs(_ value: PomodoroLog)

    @objc(addPomodoroLogs:)
    @NSManaged public func addToPomodoroLogs(_ values: NSSet)

    @objc(removePomodoroLogs:)
    @NSManaged public func removeFromPomodoroLogs(_ values: NSSet)

}
