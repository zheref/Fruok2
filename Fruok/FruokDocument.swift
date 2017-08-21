//
//  Document.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

enum FruokDocumentError: Error {
	case coreDataModelNotFound
	case coreDataModelCreationFailed
	case unhandledDocumentType
}

class FruokDocumentObjectContext: NSManagedObjectContext {

	weak var delegate: FruokDocumentObjectContextDelegate?

	override func save() throws {

		if (self.persistentStoreCoordinator?.persistentStores.count ?? 0)  == 0 {

			try self.delegate?.contextCreatePersistenStore(self)
		}
		try super.save()
	}
}

protocol FruokDocumentObjectContextDelegate: class {

	func contextCreatePersistenStore(_ context: NSManagedObjectContext) throws
}

extension UTI {

	static let fruokDocument = UTI(rawValue: "com.tristan.fruok.document")
}

class FruokDocument: NSDocument, FruokDocumentObjectContextDelegate {

	let temporaryDirectory = {

		return NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent(UUID().uuidString, isDirectory: true)
	}()

	static func databaseURLFor(documentURL: URL) -> URL {

		return documentURL.appendingPathComponent("data").appendingPathComponent("database.xml")
	}

	func contextCreatePersistenStore(_ context: NSManagedObjectContext) throws {

		try self.setupPersistentStoreWithDatabaseURL(FruokDocument.databaseURLFor(documentURL: self.temporaryDirectory))
	}

	func setupPersistentStoreWithDatabaseURL(_ url: URL) throws {

		for store in (self.managedObjectContext?.persistentStoreCoordinator?.persistentStores)! {
			try self.managedObjectContext?.persistentStoreCoordinator?.remove(store)
		}

		try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

		try self.managedObjectContext!.persistentStoreCoordinator!.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: url, options: [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSInferMappingModelAutomaticallyOption: true
			])
	}

	func setupManagedObjectContext() throws {

		guard let modelURL = Bundle.main.url(forResource: "Document", withExtension: "momd") else {

			throw FruokDocumentError.coreDataModelNotFound
		}

		guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
			throw FruokDocumentError.coreDataModelCreationFailed
		}

		model.kc_generateOrderedSetAccessors()

		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
		let context = FruokDocumentObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.delegate = self
		context.persistentStoreCoordinator = coordinator

		self.managedObjectContext = context
	}

	var managedObjectContext: NSManagedObjectContext?

	override class func autosavesInPlace() -> Bool {
		return true
	}

	override init() {
		super.init()
		try! self.setupManagedObjectContext()
	}

	override func read(from url: URL, ofType typeName: String) throws {

		guard UTI(rawValue: typeName) == .fruokDocument else {

			throw FruokDocumentError.unhandledDocumentType
		}

		let originalDataURL = FruokDocument.databaseURLFor(documentURL: url)
		let tempDataURL = FruokDocument.databaseURLFor(documentURL: self.temporaryDirectory)

		try FileManager.default.createDirectory(at: tempDataURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		try FileManager.default.copyItem(atPath: originalDataURL.path, toPath: tempDataURL.path)

		try self.setupPersistentStoreWithDatabaseURL(tempDataURL)
	}

	override func write(to url: URL, ofType typeName: String, for saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws {

		try self.managedObjectContext?.save()

		let tempDataURL = FruokDocument.databaseURLFor(documentURL: self.temporaryDirectory)
		let destinationDataURL = FruokDocument.databaseURLFor(documentURL: url)

		try FileManager.default.createDirectory(at: destinationDataURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		try FileManager.default.copyItem(atPath: tempDataURL.path, toPath: destinationDataURL.path)
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
