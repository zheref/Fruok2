//
//  Subtask+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 16.08.17.
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

}
