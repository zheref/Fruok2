//
//  PomodoroLog+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 28.08.17.
//
//

import Foundation
import CoreData


extension PomodoroLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PomodoroLog> {
        return NSFetchRequest<PomodoroLog>(entityName: "PomodoroLog");
    }

    @NSManaged public var duration: Double
    @NSManaged public var startDate: NSDate?
    @NSManaged public var session: PomodoroSession?
    @NSManaged public var subtask: Subtask?

}
