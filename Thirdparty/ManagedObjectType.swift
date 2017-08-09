//
//  ManagedObjectType.swift
//  TeachersLog
//
//  Created by Matthias Keiser on 28.06.16.
//  Copyright © 2016 Tristan Inc. All rights reserved.
//

import CoreData

protocol ManagedObjectType {
	static var entityName: String { get }
}

extension NSManagedObjectContext {

	func insertObject<A: NSManagedObject>() -> A where A: ManagedObjectType {
		guard let obj = NSEntityDescription
			.insertNewObject(forEntityName: A.entityName,
				into: self) as? A else {
					fatalError("Entity \(A.entityName) does not correspond to \(A.self)")
		}
		return obj
	}
}
