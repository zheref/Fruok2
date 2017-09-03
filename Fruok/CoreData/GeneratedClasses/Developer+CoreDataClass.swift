//
//  Developer+CoreDataClass.swift
//  
//
//  Created by Matthias Keiser on 02.09.17.
//
//

import Foundation
import CoreData

@objc(Developer)
public class Developer: PersonInfo {

}

extension Developer: ManagedObjectType {

	@nonobjc static let entityName = "Developer"
}
