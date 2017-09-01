//
//  NSManagedContext+UndoGroup.swift
//  Fruok
//
//  Created by Matthias Keiser on 24.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

extension NSManagedObjectContext {

	func undoGroupWithOperationsNoSaving(_ operations: (_ context: NSManagedObjectContext) -> Void) {

		self.undoGroupWithOperations(saving: false, operations)
	}
	func undoGroupWithOperations(saving: Bool = true, _ operations: (_ context: NSManagedObjectContext) -> Void) {

		self.processPendingChanges()
		self.undoManager?.beginUndoGrouping()
		operations(self)
		self.processPendingChanges()
		self.undoManager?.endUndoGrouping()

		if saving {
			do {
				try self.save()
			} catch {
				Swift.print(error)
			}
		}
	}
}
