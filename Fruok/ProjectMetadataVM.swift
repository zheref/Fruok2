//
//  ProjectMetadataVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 21.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit

class ProjectMetadataViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Project
	@objc private let project: Project
	required init(with model: Project) {

		self.project = model
		super.init()

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.codeName), ofType: Optional<String>.self, context: .immediateOnMain)
			.map { $0 ?? NSLocalizedString("no_code", comment: "No code name")}
			.bind(to: self.codeName)

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.commercialName), ofType: Optional<String>.self, context: .immediateOnMain)
			.map { $0 ?? NSLocalizedString("Untitled", comment: "Untitled Project")}
			.bind(to: self.commercialName)

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.duration), ofType: Optional<Int>.self, context: .immediateOnMain)
			.map { $0 ?? 0}
			.bind(to: self.durationDays)

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.deadLine), ofType: Optional<Date>.self, context: .immediateOnMain)
			.bind(to: self.deadline)

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.kind), ofType: Optional<Int>.self, context: .immediateOnMain)
			.map { FruokProjectType(optionalRawValue: $0) ?? .software}
			.bind(to: self.type)

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.client), ofType: Optional<Client>.self, context: .immediateOnMain).bind(to: self, context: .immediateOnMain) { (me, client) in

			DispatchQueue.main.async {
				me.clientFirstName.value = client?.firstName ?? ""
				me.clientLastName.value = client?.lastName ?? ""
				me.clientAddress1.value = client?.address1 ?? ""
				me.clientAddress2.value = client?.address2 ?? ""
				me.clientZIP.value = client?.zip ?? ""
				me.clientCity.value = client?.city ?? ""
				me.clientPhone.value = client?.phone ?? ""
				me.clientEmail.value = client?.email ?? ""
			}
		}

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.currency), ofType: Optional<String>.self, context: .immediateOnMain).bind(to: self, context: .immediateOnMain) { (me, currency) in

			var theCurrency = currency

			if theCurrency == nil {
				theCurrency = NSLocale.current.currencyCode
			}

			let currencyList: [String] = ProjectMetadataViewModel.allCurrencies

			var index: Int? = nil
			if let theCurrency = theCurrency {
				index = currencyList.index(of: theCurrency)
			}
			//self.currencyList = currencyList
			self.currencies.value = (selected: index, currencies: currencyList)
			self.currencyString.value = theCurrency ?? "USD"
		}

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.fee), ofType: Optional<NSDecimalNumber>.self, context: .immediateOnMain).bind(to: self, context: .immediateOnMain) { (me, fee) in

			self.fee.value = fee ?? NSDecimalNumber()
		}

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.taxName), ofType: Optional<String>.self, context: .immediateOnMain).bind(to: self, context: .immediateOnMain) { (me, taxString) in

			self.taxString.value = taxString ?? ""
		}

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.tax), ofType: Optional<NSDecimalNumber>.self, context: .immediateOnMain).bind(to: self, context: .immediateOnMain) { (me, tax) in

			self.tax.value = tax ?? NSDecimalNumber()
		}



	}

	//var currencyList: [String] = []

	static let allCurrencies: [String] = Array(Set(NSLocale.availableLocaleIdentifiers.map {

		return CFLocaleGetValue((NSLocale(localeIdentifier: $0) as CFLocale), CFLocaleKey.currencyCode) as? String
		}.flatMap { $0 }))

	private func getOrCreateClient() -> Client {

		if let client = self.project.client {
			return client
		}

		guard let context = self.project.managedObjectContext else {
			preconditionFailure()
		}

		let client: Client = context.insertObject()
		self.project.client = client
		return client
	}

	let type = Property<FruokProjectType>(.software)
	let codeName = Property<String>("")
	let commercialName = Property<String>("")
	let durationDays = Property<Int>(0)
	let deadline = Property<Date?>(nil)
	let currencies = Property<(selected: Int?, currencies: [String])>(selected:nil, currencies: [])
	let currencyString = Property<String>(NSLocale.current.currencyCode ?? "USD")
	let fee = Property<NSDecimalNumber>(0)
	let taxes = Property<(selected: Int?, taxes: [String])>(selected: nil, taxes: [
		NSLocalizedString("VAT", comment: "VAT tax name"),
		NSLocalizedString("Tax", comment: "Tax tax name")
		])
	let taxString = Property<String>(NSLocale.current.currencyCode ?? "USD")
	let tax = Property<NSDecimalNumber>(0)

	let clientFirstName = Property<String>("")
	let clientLastName = Property<String>("")
	let clientAddress1 = Property<String>("")
	let clientAddress2 = Property<String>("")
	let clientZIP = Property<String>("")
	let clientCity = Property<String>("")
	let clientPhone = Property<String>("")
	let clientEmail = Property<String>("")


	func userWantsSetProjectType(_ projectType: FruokProjectType) {
		self.project.kind = Int32(projectType.rawValue)
	}
	func userWantsSetCodeName(_ codeName: String) {
		self.project.codeName = codeName
	}
	func userWantsSetCommercialName(_ commercialName: String) {
		self.project.commercialName = commercialName
	}
	func userWantsSetDurationDays(_ days: Int) {
		self.project.duration = Int32( min(days, Int(Int32.max)) )
	}
	func userWantsSetDeadline(_ deadline: Date) {
		self.project.deadLine = deadline as NSDate
	}
	func userWantsSetCurrency(_ string: String) {
		self.project.currency = string
	}
	func userWantsSetFee(_ fee: NSDecimalNumber) {
		self.project.fee = fee
	}
	func userWantsSetTaxName(_ tax: String) {
		self.project.taxName = tax
	}
	func userWantsSetTax(_ tax: NSDecimalNumber) {
		self.project.tax = tax
	}


	func userWantsSetClientFirstName(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().firstName = string
		})
	}
	func userWantsSetClientLastName(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().lastName = string
		})
	}
	func userWantsSetClientAddress1(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().address1 = string
		})
	}
	func userWantsSetClientAddress2(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().address2 = string
		})
	}
	func userWantsSetClientZIP(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().zip = string
		})
	}
	func userWantsSetClientCity(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().city = string
		})
	}
	func userWantsSetClientPhone(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().phone = string
		})
	}
	func userWantsSetClientEmail(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateClient().email = string
		})
	}
}
