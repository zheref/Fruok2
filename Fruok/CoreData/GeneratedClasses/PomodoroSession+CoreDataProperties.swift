//
//  PomodoroSession+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 27.08.17.
//
//

import Foundation
import CoreData


extension PomodoroSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PomodoroSession> {
        return NSFetchRequest<PomodoroSession>(entityName: "PomodoroSession");
    }

    @NSManaged public var startDate: NSDate?
    @NSManaged public var duration: Double
    @NSManaged public var logs: NSOrderedSet?
    @NSManaged public var task: Task?

}

// MARK: Generated accessors for logs
extension PomodoroSession {

    @objc(insertObject:inLogsAtIndex:)
    @NSManaged public func insertIntoLogs(_ value: PomodoroLog, at idx: Int)

    @objc(removeObjectFromLogsAtIndex:)
    @NSManaged public func removeFromLogs(at idx: Int)

    @objc(insertLogs:atIndexes:)
    @NSManaged public func insertIntoLogs(_ values: [PomodoroLog], at indexes: NSIndexSet)

    @objc(removeLogsAtIndexes:)
    @NSManaged public func removeFromLogs(at indexes: NSIndexSet)

    @objc(replaceObjectInLogsAtIndex:withObject:)
    @NSManaged public func replaceLogs(at idx: Int, with value: PomodoroLog)

    @objc(replaceLogsAtIndexes:withLogs:)
    @NSManaged public func replaceLogs(at indexes: NSIndexSet, with values: [PomodoroLog])

    @objc(addLogsObject:)
    @NSManaged public func addToLogs(_ value: PomodoroLog)

    @objc(removeLogsObject:)
    @NSManaged public func removeFromLogs(_ value: PomodoroLog)

    @objc(addLogs:)
    @NSManaged public func addToLogs(_ values: NSOrderedSet)

    @objc(removeLogs:)
    @NSManaged public func removeFromLogs(_ values: NSOrderedSet)

}
