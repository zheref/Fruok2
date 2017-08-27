//
//  PomodoroLog+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 27.08.17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension PomodoroLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PomodoroLog> {
        return NSFetchRequest<PomodoroLog>(entityName: "PomodoroLog");
    }

    @NSManaged public var duration: Double
    @NSManaged public var session: PomodoroSession?
    @NSManaged public var subtask: Subtask?

}
