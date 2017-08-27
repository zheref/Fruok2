//
//  Document.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit // for result type

enum FruokDocumentError: Error {
	case coreDataModelNotFound
	case coreDataModelCreationFailed
	case unhandledDocumentType
}

enum FruokProjectType: Int, OptionalRawValueRepresentable {
	case software
	case website
	case film
}

class FruokDocumentObjectContext: NSManagedObjectContext {

	weak var delegate: FruokDocumentObjectContextDelegate?

	// We divert save requests to the document.
	override func save() throws {

		self.delegate?.save(context: self)
	}

	// This actually saves the context.
	func actuallySave() throws {

		if (self.persistentStoreCoordinator?.persistentStores.count ?? 0)  == 0 {

			try self.delegate?.contextCreatePersistenStore(self)
		}
		try super.save()
	}
}

protocol FruokDocumentObjectContextDelegate: class {

	func save(context: NSManagedObjectContext)
	func contextCreatePersistenStore(_ context: NSManagedObjectContext) throws
	func context(_ context: NSManagedObjectContext, urlForExistingAttachmentWithIdentifier identifier: String, name: String) -> URL?
	func context(_ context: NSManagedObjectContext, copyFileURLSToInbox urls: [URL], callback: @escaping ([Result<AttachmentCopyResult, NSError>]) -> Void)
	func context(_ context: NSManagedObjectContext, deleteAttachments attachmentInfos: [(identifier: String, filename: String)])
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

	static func attachmentsURLFor(documentURL: URL) -> URL {

		return documentURL.appendingPathComponent("attachments", isDirectory: true)
	}

	static func attachmentURLFor(documentURL: URL, attachmentIdentifier: String, name: String) -> URL {

		return self.attachmentsURLFor(documentURL: documentURL)
			.appendingPathComponent(attachmentIdentifier)
			.appendingPathComponent(name)
	}

	func inboxURLForAttachment(withIdentifier identifier: String, name: String) -> URL {

		return type(of: self).attachmentURLFor(documentURL: self.temporaryDirectory, attachmentIdentifier: identifier, name: name)
	}

	func savedURLForAttachment(withIdentifier identifier: String, name: String) -> URL? {

		guard let fileURL = self.fileURL else {return nil}

		return type(of: self).attachmentURLFor(documentURL: fileURL, attachmentIdentifier: identifier, name: name)
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
		context.undoManager = self.undoManager

		self.managedObjectContext = context
	}

	var managedObjectContext: FruokDocumentObjectContext?

	override class func autosavesInPlace() -> Bool {
		return true
	}
	override class func autosavesDrafts() -> Bool {
		return false
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

		do {

		try self.managedObjectContext?.actuallySave()

		let tempDataURL = FruokDocument.databaseURLFor(documentURL: self.temporaryDirectory)
		let destinationDataURL = FruokDocument.databaseURLFor(documentURL: url)

		try FileManager.default.createDirectory(at: destinationDataURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		try FileManager.default.copyItem(atPath: tempDataURL.path, toPath: destinationDataURL.path)

		if let taskStates = self.project?.taskStates {

			enum FileOp {
				case move
				case copy
				case none

				func execute(source: URL, destination: URL) throws {


					switch self {
					case .move:
						try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
						try FileManager.default.moveItem(at: source, to: destination)
					case .copy:
						try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
						try FileManager.default.copyItem(at: source, to: destination)
					case .none:
						return
					}
				}
			}

			let inboxFileOp: FileOp
			let savedFileOp: FileOp

			switch saveOperation {

			case .saveOperation:

				inboxFileOp = .copy
				savedFileOp = .none

			case .autosaveInPlaceOperation:

				inboxFileOp = .move
				savedFileOp = .move // since we write to a temp dir, we *need* to move

			case .saveAsOperation:

				inboxFileOp = .move
				savedFileOp = .copy

			case .saveToOperation:

				inboxFileOp = .copy
				savedFileOp = .copy

			case .autosaveAsOperation:

				inboxFileOp = .move
				savedFileOp = .copy

			case .autosaveElsewhereOperation:

				inboxFileOp = .copy
				savedFileOp = .copy
			}

			for state in taskStates {

				guard let tasks = (state as? TaskState)?.tasks else { continue }

				for task in tasks {

					guard let attachments = (task as? Task)?.attachments else { continue }

					for attachment in attachments {

						guard let attachment = attachment as? Attachment else { continue }

						let writeURL = type(of: self).attachmentURLFor(documentURL: url, attachmentIdentifier: attachment.identifier, name: attachment.filename)

						if let absoluteOriginalContentsURL = absoluteOriginalContentsURL {

							let originalAttachmentURL = type(of: self).attachmentURLFor(documentURL: absoluteOriginalContentsURL, attachmentIdentifier: attachment.identifier, name: attachment.filename)

							if FileManager.default.fileExists(atPath: originalAttachmentURL.path) {

								try savedFileOp.execute(source: originalAttachmentURL, destination: writeURL)
								continue
							}
						}

						let tempAttachmentURL = type(of: self).attachmentURLFor(documentURL: self.temporaryDirectory, attachmentIdentifier: attachment.identifier, name: attachment.filename)

						if FileManager.default.fileExists(atPath: tempAttachmentURL.path) {

							try inboxFileOp.execute(source: tempAttachmentURL, destination: writeURL)
						}
					}
				}
			}
		}
		} catch {
			throw error
		}
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

	func urlForExistingAttachment(with identifier: String,  name: String) -> URL? {

		if let url = self.savedURLForAttachment(withIdentifier: identifier, name: name) {

			if FileManager.default.fileExists(atPath: url.path) {
				return url
			}
		}

		let url = self.inboxURLForAttachment(withIdentifier: identifier, name: name)

		if FileManager.default.fileExists(atPath: url.path) {
			return url
		}

		return nil
	}
	
	func context(_ context: NSManagedObjectContext, urlForExistingAttachmentWithIdentifier identifier: String, name: String) -> URL? {

		return self.urlForExistingAttachment(with: identifier, name: name)
	}

	func context(_ context: NSManagedObjectContext, copyFileURLSToInbox urls: [URL], callback: @escaping ([Result<AttachmentCopyResult, NSError>]) -> Void) {

		DispatchQueue.global().async {

			var results: [Result<AttachmentCopyResult, NSError>] = []

			for url in urls {

				let identifier = UUID().uuidString
				let filename = url.lastPathComponent
				let inboxURL = self.inboxURLForAttachment(withIdentifier: identifier, name: filename)

				do {
					try FileManager.default.createDirectory(at: inboxURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
					try FileManager.default.copyItem(at: url, to: inboxURL)
					results.append(Result(AttachmentCopyResult(originalURL: url, identifier: identifier, filename: filename)))
				} catch {
					results.append(Result(error as NSError))
				}
			}

			DispatchQueue.main.async {
				callback(results)
			}
		}
	}

	func context(_ context: NSManagedObjectContext, deleteAttachments attachmentInfos: [(identifier: String, filename: String)]) {

		for (identifier, filename) in attachmentInfos {

			if let url = self.urlForExistingAttachment(with: identifier, name: filename) {
				do {try FileManager.default.removeItem(at: url.deletingLastPathComponent())} catch{}
			}
		}
	}

	func save(context: NSManagedObjectContext) {

		self.save(nil)
	}
}

struct AttachmentCopyResult {
	let originalURL: URL
	let identifier: String
	let filename: String
}
