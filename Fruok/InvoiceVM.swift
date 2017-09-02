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

extension NumberFormatter {

	static let feeFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		return formatter
	}()

	static let percentFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .percent
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

	func localeForCurrency(_ currency: String?) -> NSLocale? {

		guard let currency = currency else {return nil}

		for identifier in NSLocale.availableLocaleIdentifiers {

			let locale = NSLocale(localeIdentifier: identifier)
			if (CFLocaleGetValue((locale as CFLocale), CFLocaleKey.currencyCode) as? String) == currency {
				return locale
			}
		}

		return nil
	}
	func updateInvoice() {

		let invoiceData = InvoiceData()
		invoiceData.invoiceName.set(NSLocalizedString("Invoice", comment: "Invoice title"))
		invoiceData.projectName.set(self.project.commercialName)
		invoiceData.invoiceDate.set(DateFormatter.invoiceDateFormatter.string(from: Date()))

		invoiceData.clientName.set( (self.project.client?.firstName ?? "") + " " + (self.project.client?.lastName ?? ""))
		invoiceData.clientAddress1.set(self.project.client?.address1)
		invoiceData.clientAddress2.set(self.project.client?.address2)
		invoiceData.clientZIP.set(self.project.client?.zip)
		invoiceData.clientCity.set(self.project.client?.city)
		invoiceData.clientPhone.set(self.project.client?.phone)
		invoiceData.clientEmail.set(self.project.client?.email)

		let perTask = self.sessionFilterViewModel.sessions.grouping(by: { $0.task! })
		var tasks: [InvoiceDataTask] = []

		let currency = self.project.currency
		let currenyLocale = self.localeForCurrency(currency)

		let feeString: (NSDecimalNumber?) -> String? = { (_ number: NSDecimalNumber?) in

			guard let number = number else { return nil }

			if let theCurrenyLocale = currenyLocale {

				NumberFormatter.feeFormatter.locale = theCurrenyLocale as Locale
				if let string = NumberFormatter.feeFormatter.string(from: number) {
					return string
				}
			}
			if let currency = currency {
				return String(format: "%@ %@", currency, number.stringValue)
			}
			else {
				return number.stringValue
			}
		}

		let hourHandler = NSDecimalNumberHandler(roundingMode: .bankers, scale: 1, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
		let feeHandler = NSDecimalNumberHandler(roundingMode: .bankers, scale: 2, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
		let oneHour = NSDecimalNumber(mantissa: 60, exponent: 1, isNegative: false)
		let feePerHour = self.project.fee ?? NSDecimalNumber.zero
		var totalHours = NSDecimalNumber.zero
		var totalFee = NSDecimalNumber.zero

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

			let totalSeconds = perTask[task]!.reduce(0.0, {  (result, session) in return result + session.totalDuration })
			let seconds = NSDecimalNumber(mantissa: UInt64(abs(floor(totalSeconds))), exponent: 1, isNegative: false)
			let hours = seconds.dividing(by: oneHour, withBehavior: hourHandler)
			let taskFee = feePerHour.multiplying(by: hours, withBehavior: feeHandler)

			totalHours = totalHours.adding(hours, withBehavior: hourHandler)
			totalFee = totalFee.adding(taskFee, withBehavior: feeHandler)


			taskData.quantity.set(hours.stringValue)
			taskData.price.set(feeString(feePerHour))
			taskData.total.set(feeString(taskFee))

			tasks.append(taskData)
		}

		invoiceData.tasks.set(tasks)

		invoiceData.subtotal.set(feeString(totalFee))

		let taxPercent: NSDecimalNumber? = self.project.tax
		let taxName: String? = self.project.taxName

		if taxPercent != nil || taxName != nil {

			let taxData = InvoiceDataTax()
			let taxAmount = taxPercent?.multiplying(by: totalFee, withBehavior: feeHandler)
			totalFee = totalFee.adding(taxAmount ?? NSDecimalNumber.zero, withBehavior: feeHandler)

			taxData.percent.set(String(format: "%@: %@", taxName ?? "", taxPercent != nil ? NumberFormatter.percentFormatter.string(from: taxPercent!)! : ""))

			taxData.amount.set(feeString(taxAmount))
			invoiceData.tax.set(taxData)
		}

		invoiceData.grandTotal.set(feeString(totalFee))

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
