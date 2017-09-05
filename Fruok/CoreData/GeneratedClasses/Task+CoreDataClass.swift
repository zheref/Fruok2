//
//  Task+CoreDataClass.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(Task)
public class Task: BaseTask {

}

extension Task: ManagedObjectType {

	@nonobjc static let entityName = "Task"
}


extension Task {

	func importAttachments(_ urls: [URL], at index: Int) {

		guard let fruokDocumentContext = self.managedObjectContext as? FruokDocumentObjectContext else {
			return
		}

		guard let contextDelegate = fruokDocumentContext.delegate else {
			return
		}

		contextDelegate.context(fruokDocumentContext, copyFileURLSToInbox: urls) { [weak self] results in

			guard let context = self?.managedObjectContext else {
				return
			}

			context.processPendingChanges()
			context.undoManager?.disableUndoRegistration()
			defer {
				context.processPendingChanges()
				context.undoManager?.enableUndoRegistration()
			}

			var attachments: [Attachment] = []

			for result in results {

				switch result {
				case .success(let copyResult):

					let attachment: Attachment = context.insertObject()
					attachment.identifier = copyResult.identifier
					attachment.filename = copyResult.filename
					attachments.append(attachment)

				case .failure(let error):
					NSLog("Error copying an attachment: %@", error)
				}
			}

			let indexes = IndexSet(integersIn: (index + 0)..<(index + attachments.count))
			self?.insertIntoAttachments(attachments, at: indexes as NSIndexSet)
		}
	}

	func deleteAttachments(_ attachments: [Attachment]) {

		let tuples = attachments.map { ($0.identifier, $0.filename) }

		self.managedObjectContext?.processPendingChanges()
		self.managedObjectContext?.undoManager?.disableUndoRegistration()
		defer {
			self.managedObjectContext?.processPendingChanges()
			self.managedObjectContext?.undoManager?.enableUndoRegistration()
		}

		for attachment in attachments {
			self.removeFromAttachments(attachment)
			self.managedObjectContext?.delete(attachment)
		}

		if let context = self.managedObjectContext as? FruokDocumentObjectContext {
			context.delegate?.context(context, deleteAttachments: tuples)
		}

	}
}
