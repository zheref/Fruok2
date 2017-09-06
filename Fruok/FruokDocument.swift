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

	fileprivate static let kAttachmentsDirectoryName = "attachments"
	fileprivate static let kDataDirectoryName = "data"
	fileprivate static let kDatabaseName = "database.xml"

	lazy var documentFileWrapper: FileWrapper = {

		return FileWrapper(directoryWithFileWrappers:[:])
	}()
	var attachmentsFileWrapper: FileWrapper {

		if let attachmentsWrapper = self.documentFileWrapper.fileWrappers?[FruokDocument.kAttachmentsDirectoryName] {
			return attachmentsWrapper
		}

		let attachmentsWrapper = FileWrapper(directoryWithFileWrappers:[:])
		attachmentsWrapper.preferredFilename = FruokDocument.kAttachmentsDirectoryName
		self.documentFileWrapper.addFileWrapper(attachmentsWrapper)
		return attachmentsWrapper
	}

	var dataContainerFileWrapper: FileWrapper {

		if let dataWrapper = self.documentFileWrapper.fileWrappers?[FruokDocument.kDataDirectoryName] {
			return dataWrapper
		}

		let dataWrapper = FileWrapper(directoryWithFileWrappers:[:])
		dataWrapper.preferredFilename = FruokDocument.kDataDirectoryName
		self.documentFileWrapper.addFileWrapper(dataWrapper)
		return dataWrapper
	}

	lazy var tempDatabaseURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
		.appendingPathComponent(UUID().uuidString, isDirectory: false)


	static func databaseURLFor(documentURL: URL) -> URL {

		return documentURL.appendingPathComponent("data").appendingPathComponent("database.xml")
	}

	func contextCreatePersistenStore(_ context: NSManagedObjectContext) throws {

		try self.setupPersistentStoreWithDatabaseURL(self.tempDatabaseURL)
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
		return true
	}

	override init() {
		super.init()
		try! self.setupManagedObjectContext()
	}

	override func fileWrapper(ofType typeName: String) throws -> FileWrapper {

		guard UTI(rawValue: typeName) == .fruokDocument else {

			throw FruokDocumentError.unhandledDocumentType
		}

		try self.managedObjectContext?.actuallySave()

		let databaseData = try Data(contentsOf:self.tempDatabaseURL)
		let databaseFileWrapper = FileWrapper(regularFileWithContents: databaseData)
		databaseFileWrapper.preferredFilename = FruokDocument.kDatabaseName
		if let previous = self.dataContainerFileWrapper.fileWrappers?[FruokDocument.kDatabaseName] {
			self.dataContainerFileWrapper.removeFileWrapper(previous)
		}
		self.dataContainerFileWrapper.addFileWrapper(databaseFileWrapper)

		return self.documentFileWrapper
	}
	override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {

		guard UTI(rawValue: typeName) == .fruokDocument else {

			throw FruokDocumentError.unhandledDocumentType
		}

		self.documentFileWrapper = fileWrapper

		if let databaseWrapper = fileWrapper.fileWrappers?[FruokDocument.kDataDirectoryName]?.fileWrappers?[FruokDocument.kDatabaseName] {
			try databaseWrapper.regularFileContents?.write(to: self.tempDatabaseURL)
		}
		try self.setupPersistentStoreWithDatabaseURL(self.tempDatabaseURL)
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

	func context(_ context: NSManagedObjectContext, urlForExistingAttachmentWithIdentifier identifier: String, name: String) -> URL? {

		return self.urlForExistingAttachment(with: identifier, filename: name)
	}

	func context(_ context: NSManagedObjectContext, copyFileURLSToInbox urls: [URL], callback: @escaping ([Result<AttachmentCopyResult, NSError>]) -> Void) {

		self.addAttachments(with: urls, callback: callback)
	}

	func context(_ context: NSManagedObjectContext, deleteAttachments attachmentInfos: [(identifier: String, filename: String)]) {

		for (identifier, _) in attachmentInfos {

			self.deleteAttachment(with: identifier)
		}
	}

	func save(context: NSManagedObjectContext) {

		self.save(nil)
	}

	var contentViewController: DocumentContentViewController? {
		return self.windowControllers.first?.contentViewController as? DocumentContentViewController
	}
	var contentViewModel: DocumentContentViewModel? {
		return self.contentViewController?.viewModel
	}
}

// Attachments
extension FruokDocument {

	func addAttachments(with urls: [URL], callback: @escaping ([Result<AttachmentCopyResult, NSError>]) -> Void) {

		var results: [Result<AttachmentCopyResult, NSError>] = []

		for url in urls {

			let identifier = UUID().uuidString
			do {
				let (parent, payload) = try addAttachment(with: url, identifier: identifier)
				let filename = parent.keyForChildFileWrapper(payload)!
				results.append(Result(AttachmentCopyResult(originalURL: url, identifier: identifier, filename: filename)))
			} catch {
				results.append(Result(error as NSError))
			}
		}

		DispatchQueue.main.async {
			callback(results)
		}
	}

	func addAttachment(with url: URL, identifier: String) throws -> (FileWrapper, FileWrapper) {

		let payloadWrapper = try FileWrapper(url: url, options: [.immediate])
		let superWrapper = FileWrapper(directoryWithFileWrappers: [url.lastPathComponent : payloadWrapper])
		superWrapper.preferredFilename = identifier
		self.attachmentsFileWrapper.addFileWrapper(superWrapper)
		return (superWrapper, payloadWrapper)
	}

	func deleteAttachment(with identifier: String) {

		if let wrapper = self.attachmentsFileWrapper.fileWrappers?[identifier] {
			self.attachmentsFileWrapper.removeFileWrapper(wrapper)
		}
	}

	func urlForExistingAttachment(with identifier: String, filename: String) -> URL? {

		return self.fileURL?.appendingPathComponent(FruokDocument.kAttachmentsDirectoryName).appendingPathComponent(identifier)
		.appendingPathComponent(filename)

	}
}

extension FruokDocument {

	@IBAction func startPomodoroSession(_ sender: TaskDetailViewController) {

		if let viewModel = sender.viewModel {
			(NSApp.delegate as? AppDelegate)?.pomodoroController.documentRequestPomodoroStart(self, forTask: viewModel.task)
		}
	}
}

struct AttachmentCopyResult {
	let originalURL: URL
	let identifier: String
	let filename: String
}
