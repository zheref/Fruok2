//
//  InvoiceVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 30.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import ReactiveKit
import Mustache

extension DateFormatter {

	static let invoiceDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = .none
		formatter.dateStyle = .short
		return formatter
	}()
}

class InvoiceViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Project
	@objc private let project: Project
	required init(with model: Project) {
		self.project = model
		super.init()
		self.updateInvoice()
	}

	lazy var sessionFilterViewModel: SessionFilterViewModel = {

		let filterViewModel = SessionFilterViewModel(with: self.project)
		filterViewModel.delegate = self
		filterViewModel.groupControlVisible.value = false
		return filterViewModel
	}()

	var invoiceTemplateURL: URL = {
		return Bundle.main.url(forResource: "invoice.html", withExtension: "mustache")!
	}()

	lazy var invoiceTemplate: Template = {

		let template = try! Template(URL: self.invoiceTemplateURL)
		return template
	}()

	func updateInvoice() {

		let invoiceData = InvoiceData()
		invoiceData.invoiceName.set(NSLocalizedString("Invoice", comment: "Invoice title"))
		invoiceData.projectName.set(self.project.commercialName)
		invoiceData.invoiceDate.set(DateFormatter.invoiceDateFormatter.string(from: Date()))

		let perTask = self.sessionFilterViewModel.sessions.grouping(by: { $0.task! })
		var tasks: [InvoiceDataTask] = []

		for task in perTask.keys.sorted(by: {($0.name ?? "") < ($1.name ?? "") }) {

			let taskData = InvoiceDataTask()
			taskData.name.set(task.name)

			if let subtasks = task.subtasks {
				taskData.taskDescription.set( subtasks.reduce("", { (result: String, subtask) in

					if let name = (subtask as? Subtask)?.name {
						return result + " " + name
					} else {
						return result
					}
				}))
			}

			taskData.quantity.set(
				{
				let totalSeconds = perTask[task]!.reduce(0.0, {  (result, session) in return result + session.totalDuration })
				let totalHours = totalSeconds / (60 * 60)
				return NSString(format: "%.1f", totalHours) as String
				}()
			)

			tasks.append(taskData)
		}

		invoiceData.tasks.set(tasks)

		let htmlString: String
		do {
			htmlString = try self.invoiceTemplate.render(invoiceData.unboxedData())
		} catch { return }

		self.htmlInfo.value = (htmlString, self.invoiceTemplateURL.deletingLastPathComponent())
	}

	let htmlInfo = Property<(htmlString: String, baseURL: URL)?>(nil)
}

extension InvoiceViewModel: SessionFilterViewModelDelegate {

	func sessionFilterViewModelDidChangeSessions(_ sessionFilter: SessionFilterViewModel) {
		self.updateInvoice()
	}
	func sessionFilterViewModelDidChangeGroupMode(_ sessionFilter: SessionFilterViewModel) {
	}

}
