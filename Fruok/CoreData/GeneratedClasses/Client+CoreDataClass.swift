//
//  Client+CoreDataClass.swift
//  
//
//  Created by Matthias Keiser on 01.09.17.
//
//

import Foundation
import CoreData

@objc(Client)
public class Client: PersonInfo {

}

extension Client: ManagedObjectType {

	@nonobjc static let entityName = "Client"
}
