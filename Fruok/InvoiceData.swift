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
	lazy private(set) var clientEmail: InvoiceDataProperty<String>	= { self.makeProperty("CLIENT_EMAIL") }()
	lazy private(set) var invoiceDate: InvoiceDataProperty<String>	= { self.makeProperty("INVOICE_DATE") }()
	lazy private(set) var dueDate: InvoiceDataProperty<String>	= { self.makeProperty("DUE_DATE") }()

	lazy private(set) var subtotal: InvoiceDataProperty<String>	= { self.makeProperty("SUBTOTAL") }()
	lazy private(set) var grandTotal: InvoiceDataProperty<String>	= { self.makeProperty("GRAND_TOTAL") }()

	lazy private(set) var footerText: InvoiceDataProperty<String>	= { self.makeProperty("FOOTER_TEXT") }()

	lazy var tax: InvoiceDataProperty<InvoiceDataTax>				= { self.makeProperty("TAX") }()
	lazy var tasks: InvoiceDataProperty<[InvoiceDataTask]>			= { self.makeProperty("TASKS") }()
}

//class DataProperty<Content>: ExpressibleByStringLiteral {
//
//	typealias StringLiteralType = String
//	typealias ExtendedGraphemeClusterLiteralType = String
//	typealias UnicodeScalarLiteralType = String
//
//	let key: String
//
//	convenience init(_ stringLiteral: String) {
//		self.init(stringLiteral: stringLiteral)
//	}
//
//	required init(stringLiteral value: String) {
//		self.key = value
//	}
//
//	required init(extendedGraphemeClusterLiteral value: DataProperty.ExtendedGraphemeClusterLiteralType) {
//		self.key = value
//	}
//
//	required init(unicodeScalarLiteral value: DataProperty.UnicodeScalarLiteralType) {
//		self.key = value
//	}
//
//	var value: Content?
//}
//
//typealias StringDataProperty = DataProperty<String>
//typealias DictDataProperty = DataProperty<Dictionary<String, DataProperty<String>>>
//
//struct SSS<Value> {
//
//	let setter: (Value) -> Void
//	let getter: () -> Value?
//	let key: String
//
//	func set(_ value: Value) {
//		setter(value)
//	}
//	var get: Value? {
//		return getter()
//	}
//
//}
//class AAAA {
//
//	var data: [String: Any] = [:]
//
//	lazy var invoiceName: SSS<String> = {
//
//		return self.makeProperty("lll")
//	}()
//
//	func makeProperty<Value>(_ key: String) -> SSS<Value> {
//
//		return SSS(setter: { value in
//			self.data[key] = value
//		}, getter: {
//			return self.data[key] as? Value
//		}, key: key)
//	}
//}
//
//
//
//struct InvoiceData {
//
//	var dict: Dictionary<String, Any> {
//
//		var dict = [
//
//			"INVOICE_NAME" = StringDataProperty("INVOICE_NAME")
//		]
//	}
//	let invoiceName		: StringDataProperty = "INVOICE_NAME"
//	let companyName		: StringDataProperty = "COMPANY_NAME"
//	let companyAddress1	: StringDataProperty = "COMPANY_ADDRESS1"
//	let companyAddress2	: StringDataProperty = "COMPANY_ADDRESS2"
//	let companyPhone	: StringDataProperty = "COMPANY_PHONE"
//	let companyEmail	: StringDataProperty = "COMPANY_EMAIL"
//
//	let projectName		: StringDataProperty = "PROJECT_NAME"
//
//	let clientName		: StringDataProperty = "CLIENT_NAME"
//	let clientAddress1	: StringDataProperty = "CLIENT_ADDRESS1"
//	let clientAddress2	: StringDataProperty = "CLIENT_ADDRESS2"
//	let clientEmail		: StringDataProperty = "CLIENT_EMAIL"
//
//	let invoiceDate		: StringDataProperty = "INVOICE_DATE"
//	let dueDate			: StringDataProperty = "DUE_DATE"
//
//	let subTotal		: StringDataProperty = "SUBTOTAL"
//	let grandTotal		: StringDataProperty = "GRAND_TOTAL"
//
//	let footerText		: StringDataProperty = "FOORTER_TEXT"
//
//	let tax
////	"TAX": {
////	"PERCENT": "Tax 10%",
////	"AMOUNT": "$1220"
////	},
//
//	/*"TASKS": [
//	{
//	"NAME": "Task1",
//	"DESCRIPTION": "subtask1, subtask2, subtask3",
//	"PRICE": "$40",
//	"QTY": "4.6",
//	"TOTAL": "$184"
//	}, {
//	"NAME": "Task2",
//	"DESCRIPTION": "subtask1, subtask2, subtask3",
//	"PRICE": "$40",
//	"QTY": "10.0",
//	"TOTAL": "$400"
//	}
//	],
//
//*/
//
//	var stringPropertyArray: [DataProperty<String>] {
//
//		return [
//
//			invoiceName,
//			companyName,
//			companyAddress1,
//			companyAddress2,
//			companyPhone,
//			companyEmail,
//			projectName,
//			clientName,
//			clientAddress1,
//			clientAddress2,
//			clientEmail,
//			invoiceDate,
//			dueDate
//		]
//	}
//	var dictionary: [String: Any] {
//
//		let properties = [invoiceName, companyName]
//
//
//		var result: [String: Any] = [:]
//		for property in self.stringPropertyArray {
//
//			if let value = property.value {
//				result[key] = value
//			}
//		}
//		return result
//	}
//}
