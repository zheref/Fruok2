//
//  Project+CoreDataClass.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(Project)
public class Project: NSManagedObject {

}

extension Project: ManagedObjectType {

	@nonobjc static let entityName = "Project"
}

extension Project {

	var labels: Set<Label> {

		guard let context = self.managedObjectContext else {
			return Set()
		}

		let fetchRequest: NSFetchRequest<Label> = NSFetchRequest(entityName: Label.entityName)
		do {
			return  Set(try context.fetch(fetchRequest))
		} catch {
			return Set()
		}
	}

	func purgeUnusedLabels() {

		for label in self.labels {

			if (label.tasks?.count ?? 0) == 0 {
				self.managedObjectContext?.delete(label)
			}
		}
	}
}
