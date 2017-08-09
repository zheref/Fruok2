//
//  Document.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class FruokDocument: NSPersistentDocument {

	override class func autosavesInPlace() -> Bool {
		return true
	}

	override init() {
		super.init()
		self.managedObjectModel?.kc_generateOrderedSetAccessors()
	}
	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController

		let viewModel = DocumentContentViewModel(with: self)
		(windowController.contentViewController as! DocumentContentViewController).set(viewModel:viewModel)
		self.addWindowController(windowController)
	}

	lazy var project: Project? = {

		guard let context = self.managedObjectContext else {
			return nil
		}
		var projects: [Project] = []

		let fetchRequest: NSFetchRequest<Project> = NSFetchRequest(entityName: Project.entityName)
		do {
			projects = try context.fetch(fetchRequest)
		} catch {
			return nil
		}

		return projects.first ?? self.createInitialProject()
	}()

	func createInitialProject() -> Project {

		self.managedObjectContext?.processPendingChanges()
		self.undoManager?.disableUndoRegistration()
		let project = self.managedObjectContext!.insertObject() as Project
		self.managedObjectContext?.processPendingChanges()
		self.undoManager?.enableUndoRegistration()
		return project
	}
}
