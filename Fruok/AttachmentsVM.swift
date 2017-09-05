//
//  AttachmentsVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 22.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

extension UTI {

	static let fruokAttachment = UTI(rawValue: "com.tristan.fruok.attachment")
}

extension Attachment: NSPasteboardWriting {

	public func writableTypes(for pasteboard: NSPasteboard) -> [String] {
		return [UTI.fruokAttachment.rawValue]
	}

	public func pasteboardPropertyList(forType type: String) -> Any? {

		switch UTI(rawValue: type) {

		case UTI.fruokAttachment:
			return self.objectID.uriRepresentation().absoluteString

		default:
			return nil
		}
	}
}

class AttachmentsViewModel: NSObject, MVVMViewModel, CollectionDragAndDropViewModel {

	typealias MODEL = Task
	@objc private let task: Task
	required init(with model: Task) {
		self.task = model
		super.init()
		self.addObserver(self, forKeyPath: #keyPath(AttachmentsViewModel.task.attachments), options: .initial, context: &kAttachmentsContext)
	}

	deinit {
		self.removeObserver(self, forKeyPath: #keyPath(AttachmentsViewModel.task.attachments))
	}

	private var kAttachmentsContext = "kAttachmentsContext"

	var model: Task {
		return self.task
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

		if context == &kAttachmentsContext {

			self.reactToCoreDataKVOMessage(change)
		}
	}

	let modelCollectionKeyPath = #keyPath(Task.attachments)
	var supressTaskStateObservation = false

	var numCollectionObjects = Property<Int>(0)
	var viewActions = Property<CollectionViewModelActions?>(nil)

	func pasteboardItemForTastState(at index: Int) -> NSPasteboardWriting? {

		return self.task.attachments?[index] as? Attachment
	}

	func attachmentViewModel(for index: Int) -> AttachmentCellViewModel? {

		guard let attachment = self.task.attachments?[index] as? Attachment else {
			return nil
		}

		let fileURL = attachment.fileURL

		return AttachmentCellViewModel(with: fileURL, filename: attachment.filename)
	}

	func userWantsAddAttachments(_ urls: [URL]) {

		self.task.importAttachments(urls)

		do { try self.task.managedObjectContext?.save() } catch {}
	}

	struct AttachmentDeleteConfirmationInfo {

		let question: String
		let detailString: String
		let callback: () -> Void
	}

	let attchmentDeleteConfirmation = Property<AttachmentDeleteConfirmationInfo?>(nil)

	func userWantsDeleteAttachments(at indexes: IndexSet) {

		guard let attachments = self.task.attachments?.objects(at: indexes) as? [Attachment] else {
			return
		}

		let question: String

		if attachments.count > 1 {

			question = NSString(format: NSLocalizedString("Delete %i Files", comment: "Multi attachment deletion") as NSString, indexes.count) as String
		} else {
			question = NSString(format: NSLocalizedString("Delete File %@?", comment: "Attachment deletion") as NSString, attachments.first?.filename ?? "_untitled_") as String
		}

		let info = AttachmentDeleteConfirmationInfo(
			question: question,
			detailString: NSLocalizedString("This action can not be undone", comment: "Attachment deletion warning"),

			callback: { [weak self] in

				self?.task.deleteAttachments(attachments)
		})

		self.attchmentDeleteConfirmation.value = info
	}

	func userWantsOpenAttachmentsAt(indexes: IndexSet) {

		guard let attachments = self.task.attachments else { return }

		let urls: [URL] = attachments.objects(at: indexes).map{ ($0 as? Attachment)?.fileURL }.flatMap {$0}

		self.attachmentsToOpen.value = urls
	}

	var attachmentsToOpen = Property<[URL]>([])

}
