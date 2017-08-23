//
//  Attachment+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 22.08.17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Attachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment");
    }

    @NSManaged public var filename: String
    @NSManaged public var identifier: String
    @NSManaged public var task: Task?

}
