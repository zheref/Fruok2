//
//  AttachmentOverviewVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 04.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

struct AttachmentOverviewCellViewModel: MVVMViewModel {

	typealias MODEL = Optional<URL>
	let attachmentURL: Property<URL?>
	let filename = Property<String>("")
	let taskName = Property<String>("")

	init(with url: URL?, filename: String, taskName: String) {
		self.init(with: url)
		self.filename.value = filename
	}
	init(with url: URL?) {
		self.attachmentURL = Property(url)
	}
}

class AttachmentOverviewViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Project
	@objc private let project: Project

	required init(with model: Project) {
		self.project = model
		super.init()

		NotificationCenter.default.reactive.notification(name: .NSManagedObjectContextObjectsDidChange, object: self.project.managedObjectContext).observeNext { [weak self] note in

			self?.updateAttachments()

		}.dispose(in: bag)

		self.updateAttachments()
	}

	func updateAttachments() {

		let taskFetchRequest: NSFetchRequest<Attachment> = Attachment.fetchRequest()

		let attachments: [Attachment]

		do { attachments = try self.project.managedObjectContext?.fetch(taskFetchRequest) ?? [] } catch { attachments = [] }

		self.attachments.value = attachments
	}

	let attachments = Property<[Attachment]>([])
	var attachmentsToOpen = Property<[URL]>([])
	let attchmentDeleteConfirmation = Property<AttachmentDeleteConfirmationInfo?>(nil)

	enum ColumnName: String, OptionalRawValueRepresentable {
		case Preview
		case Task
		case Name
	}

	func attachmentViewModel<VIEWMODEL: MVVMViewModel>(for index: Int, column: ColumnName) -> VIEWMODEL {

		let attachment = self.attachments.value[index]

		switch column {
		case .Preview:
			return ImageTableCellViewModel(with: attachment.fileURL) as! VIEWMODEL
		case .Task:
			return  LabelTableCellViewModel(with: attachment.task?.name) as! VIEWMODEL
		case .Name:
			return LabelTableCellViewModel(with: attachment.name) as! VIEWMODEL
		}
	}

	func userWantsSetSetSortDescriptors(_ descriptors: [NSSortDescriptor]) {

		self.attachments.value = (self.attachments.value as NSArray).sortedArray(using: descriptors) as! [Attachment]
	}

	func userWantsOpenAttachmentsAt(indexes: IndexSet) {

		let attachments = self.attachments.value as NSArray

		let urls: [URL] = attachments.objects(at: indexes).map{ ($0 as? Attachment)?.fileURL }.flatMap {$0}

		self.attachmentsToOpen.value = urls
	}

	struct AttachmentDeleteConfirmationInfo {

		let question: String
		let detailString: String
		let callback: () -> Void
	}

	func userWantsDeleteAttachments(at indexes: IndexSet) {

		guard let attachments = (self.attachments.value as NSArray).objects(at: indexes) as? [Attachment] else {
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

			callback: { 
				for attachment in attachments {
					attachment.task?.deleteAttachments([attachment])
				}
		})

		self.attchmentDeleteConfirmation.value = info
	}
}
