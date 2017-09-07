//
//  AttachmentSelectorViewModel.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.09.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

class AttachmentSelectorViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Task
	private let task: Task
	private let project: Project

	required init(with model: Task) {
		self.task = model
		self.project = (task.state?.project)!
		super.init()

		NotificationCenter.default.reactive.notification(name: .NSManagedObjectContextObjectsDidChange, object: self.project.managedObjectContext).observeNext { [weak self] note in

			self?.updateAttachments()

			}.dispose(in: bag)

		self.updateAttachments()
	}

	func updateAttachments() {

		let attachments: [Attachment] = (self.project.attachments?.array ?? []).flatMap { $0 as? Attachment }
			.filter {
				guard let tasks = $0.tasks else {
					return true
				}
				return !tasks.contains(self.task)
		}

		self.attachments.value = attachments
	}

	let attachments = Property<[Attachment]>([])
	var attachmentsToOpen = Property<[URL]>([])

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
			let taskNames = attachment.tasks?.flatMap { ($0 as? Task)?.name }.sorted().joined(separator: " ") ?? ""
			return  LabelTableCellViewModel(with: taskNames) as! VIEWMODEL
		case .Name:
			return LabelTableCellViewModel(with: attachment.name) as! VIEWMODEL
		}
	}

	func userWantsSetSetSortDescriptors(_ descriptors: [NSSortDescriptor]) {

		self.attachments.value = (self.attachments.value as NSArray).sortedArray(using: descriptors) as! [Attachment]
	}

	func userWantsAttachAttachments(at indexes: IndexSet) {

		let toAttach = indexes.map { self.attachments.value[$0] }
		self.task.addToAttachments(NSOrderedSet(array: toAttach))
	}
}
