//
//  InvoiceData.swift
//  Fruok
//
//  Created by Matthias Keiser on 31.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

struct InvoiceDataProperty<Value> {

	let setter: (Value?) -> Void
	let getter: () -> Value?
	let key: String

	func set(_ value: Value?) {
		setter(value)
	}
	var get: Value? {
		return getter()
	}
}

func unboxedInvoiceData(_ originalDict: [String: Any]) -> [String: Any] {

	var result: [String: Any] = [:]

	for (key, value) in originalDict {

		let unboxed: Any

		if let boxed = value as? InvoiceDataBase {
			unboxed = boxed.data
		} else {
			unboxed = value
		}

		if let dict = unboxed as? Dictionary<String, Any> {
			result[key] = unboxedInvoiceData(dict)
		} else if let array = unboxed as? [Any] {
			result[key] = unboxedInvoiceData(array)
		} else {
			result[key] = unboxed
		}
	}
	return result
}

func unboxedInvoiceData(_ originalArray: [Any]) -> [Any] {

	var result: [Any] = []

	for value in originalArray {

		let unboxed: Any

		if let boxed = value as? InvoiceDataBase {
			unboxed = boxed.data
		} else {
			unboxed = value
		}

		if let dict = unboxed as? Dictionary<String, Any> {
			result += [unboxedInvoiceData(dict)]
		} else if let array = unboxed as? [Any] {
			result += [unboxedInvoiceData(array)]
		} else {
			result += [unboxed]
		}
	}
	return result
}


class InvoiceDataBase {

	var data: [String: Any] = [:]

	func makeProperty<Value>(_ key: String) -> InvoiceDataProperty<Value> {

		return InvoiceDataProperty(setter: { value in
			if let value = value {
				self.data[key] = value
			} else {
				self.data.removeValue(forKey: key)
			}
		}, getter: {
			return self.data[key] as? Value
		}, key: key)
	}

	func unboxedData() -> [String: Any] {

		return unboxedInvoiceData(self.data)
	}
}

class InvoiceDataTax: InvoiceDataBase {

	lazy var percent: InvoiceDataProperty<String>	= { self.makeProperty("PERCENT") }()
	lazy var amount: InvoiceDataProperty<String>	= { self.makeProperty("AMOUNT") }()
}

class InvoiceDataTask: InvoiceDataBase {

	lazy var name: InvoiceDataProperty<String>				= { self.makeProperty("NAME") }()
	lazy var taskDescription: InvoiceDataProperty<String>	= { self.makeProperty("DESCRIPTION") }()
	lazy var price: InvoiceDataProperty<String>				= { self.makeProperty("PRICE") }()
	lazy var quantity: InvoiceDataProperty<String>			= { self.makeProperty("QTY") }()
	lazy var total: InvoiceDataProperty<String>				= { self.makeProperty("TOTAL") }()
}

class InvoiceData: InvoiceDataBase {

	lazy private(set) var invoiceName: InvoiceDataProperty<String>	= { self.makeProperty("INVOICE_NAME") }()
	lazy private(set) var companyName: InvoiceDataProperty<String>	= { self.makeProperty("COMPANY_NAME") }()
	lazy private(set) var companyAddress1: InvoiceDataProperty<String>	= { self.makeProperty("COMPANY_ADDRESS1") }()
	lazy private(set) var companyAddress2: InvoiceDataProperty<String>	= { self.makeProperty("COMPANY_ADDRESS2") }()
	lazy private(set) var companyPhone: InvoiceDataProperty<String>	= { self.makeProperty("COMPANY_PHONE") }()
	lazy private(set) var companyEmail: InvoiceDataProperty<String>	= { self.makeProperty("COMPANY_EMAIL") }()

	lazy private(set) var projectName: InvoiceDataProperty<String>	= { self.makeProperty("PROJECT_NAME") }()

	lazy private(set) var clientName: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_NAME") }()
	lazy private(set) var clientAddress1: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_ADDRESS1") }()
	lazy private(set) var clientAddress2: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_ADDRESS2") }()
	lazy private(set) var clientZIP: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_ZIP") }()
	lazy private(set) var clientCity: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_CITY") }()
	lazy private(set) var clientPhone: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_PHONE") }()
	lazy private(set) var clientEmail: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_EMAIL") }()
	lazy private(set) var invoiceDate: InvoiceDataProperty<String>	= { self.makeProperty("INVOICE_DATE") }()
	lazy private(set) var dueDate: InvoiceDataProperty<String>	= { self.makeProperty("DUE_DATE") }()

	lazy private(set) var subtotal: InvoiceDataProperty<String>	= { self.makeProperty("SUBTOTAL") }()
	lazy private(set) var grandTotal: InvoiceDataProperty<String>	= { self.makeProperty("GRAND_TOTAL") }()

	lazy private(set) var footerText: InvoiceDataProperty<String>	= { self.makeProperty("FOOTER_TEXT") }()

	lazy var tax: InvoiceDataProperty<InvoiceDataTax>				= { self.makeProperty("TAX") }()
	lazy var tasks: InvoiceDataProperty<[InvoiceDataTask]>			= { self.makeProperty("TASKS") }()
}
