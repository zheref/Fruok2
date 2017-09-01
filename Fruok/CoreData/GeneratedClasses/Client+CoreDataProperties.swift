//
//  Client+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 01.09.17.
//
//

import Foundation
import CoreData


extension Client {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Client> {
        return NSFetchRequest<Client>(entityName: "Client");
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var address1: String?
    @NSManaged public var address2: String?
    @NSManaged public var phone: String?
    @NSManaged public var email: String?
    @NSManaged public var zip: String?
    @NSManaged public var city: String?
    @NSManaged public var projects: NSSet?

}

// MARK: Generated accessors for projects
extension Client {

    @objc(addProjectsObject:)
    @NSManaged public func addToProjects(_ value: Project)

    @objc(removeProjectsObject:)
    @NSManaged public func removeFromProjects(_ value: Project)

    @objc(addProjects:)
    @NSManaged public func addToProjects(_ values: NSSet)

    @objc(removeProjects:)
    @NSManaged public func removeFromProjects(_ values: NSSet)

}
