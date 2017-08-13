//
//  NSManagedObjectContext+URI.swift
//  Fruok
//
//  Created by Matthias Keiser on 12.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

extension NSManagedObjectContext {

	func object(withURIString: String) -> NSManagedObject? {

		guard let url = URL(string: withURIString) else {
			return nil
		}

		return self.object(withURI: url)
	}

	func object(withURI uri: URL) -> NSManagedObject? {

		guard let objectID = self.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
			return nil
		}

		let object = self.object(with: objectID)

		if object.isFault {
			return object
		}

		let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest()
		fetchRequest.entity = object.entity
		let predicate = NSPredicate(format: "SELF == %@", argumentArray: [object])
		fetchRequest.predicate = predicate

		do {
			return try self.fetch(fetchRequest).first
		} catch {
			return nil
		}
	}
}
