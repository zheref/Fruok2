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

	var currentPomodoroSession: PomodoroSession?
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

extension Project {

	func importAttachments(_ urls: [URL], intoTask taskInfo: (task: Task, taskIndex: Int)) {

		self.importAttachments(urls, at: self.attachments?.count ?? 0, intoTask: taskInfo)
	}

	func importAttachments(_ urls: [URL], at index: Int, intoTask taskInfo: (task: Task, taskIndex: Int)?) {

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

			if let (task, taskIndex) = taskInfo {

				let indexes = IndexSet(integersIn: (taskIndex + 0)..<(taskIndex + attachments.count))
				task.insertIntoAttachments(attachments, at: indexes as NSIndexSet)
			}
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
			for task in (attachment.tasks ?? NSSet()) { (task as? Task)?.removeFromAttachments(attachment) }
			self.managedObjectContext?.delete(attachment)
		}

		if let context = self.managedObjectContext as? FruokDocumentObjectContext {
			context.delegate?.context(context, deleteAttachments: tuples)
		}
		
	}

}
