//
//  PomodoroSession+CoreDataClass.swift
//  
//
//  Created by Matthias Keiser on 27.08.17.
//
//

import Foundation
import CoreData

@objc(PomodoroSession)
public class PomodoroSession: NSManagedObject {

}

extension PomodoroSession: ManagedObjectType {

	@nonobjc static let entityName = "PomodoroSession"
}

extension PomodoroSession {
	static let defaultDuration: TimeInterval = 60 * 25
}

extension PomodoroSession {

	static func makeSessionWithTask(_ task: Task) -> PomodoroSession? {

		guard let context = task.managedObjectContext else { return nil }

		context.processPendingChanges()
		context.undoManager?.disableUndoRegistration()
		defer {
			context.processPendingChanges()
			context.undoManager?.enableUndoRegistration()
		}

		let session: PomodoroSession = context.insertObject()
		session.task = task
		session.duration = PomodoroSession.defaultDuration


		return session
	}

	func addLogAndStartIfNeeded(_ log: PomodoroLog) {

		guard let context = self.managedObjectContext else { return }

		context.processPendingChanges()
		context.undoManager?.disableUndoRegistration()
		defer {
			context.processPendingChanges()
			context.undoManager?.enableUndoRegistration()
		}

		self.addToLogs(log)

		if self.startDate == nil {

			self.startDate = NSDate()
		}
	}

	func startLogForSubtask(_ subtask: Subtask?, previousLog: PomodoroLog?) -> PomodoroLog? {

		guard let context = self.managedObjectContext else { return nil }

		context.processPendingChanges()
		context.undoManager?.disableUndoRegistration()
		defer {
			context.processPendingChanges()
			context.undoManager?.enableUndoRegistration()
		}

		if let previousLog = previousLog, let previousStart = previousLog.startDate {

			previousLog.duration = Date().timeIntervalSince(previousStart as Date)
		}
		
		let log: PomodoroLog = context.insertObject()
		log.subtask = subtask
		log.startDate = NSDate()
		self.addLogAndStartIfNeeded(log)
		return log
	}

	func finishSession(_ currentLog: PomodoroLog?) {

		guard let context = self.managedObjectContext else { return }

		context.processPendingChanges()
		context.undoManager?.disableUndoRegistration()
		defer {
			context.processPendingChanges()
			context.undoManager?.enableUndoRegistration()
		}
		if let currentLog = currentLog, let start = currentLog.startDate {

			currentLog.duration = Date().timeIntervalSince(start as Date)
		}

	}

	var totalDuration: TimeInterval {

		var sum: TimeInterval = 0

		for log in (self.logs?.array ?? []) {

			if let log = log as? PomodoroLog {
				sum += log.duration
			}
		}
		return sum
	}
}
