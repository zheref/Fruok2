//
//  ProjectMetadataVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 21.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import ReactiveKit
import AddressBook

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

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.developer), ofType: Optional<Developer>.self, context: .immediateOnMain).bind(to: self, context: .immediateOnMain) { (me, client) in

			DispatchQueue.main.async {
				me.devFirstName.value = client?.firstName ?? ""
				me.devLastName.value = client?.lastName ?? ""
				me.devAddress1.value = client?.address1 ?? ""
				me.devAddress2.value = client?.address2 ?? ""
				me.devZIP.value = client?.zip ?? ""
				me.devCity.value = client?.city ?? ""
				me.devPhone.value = client?.phone ?? ""
				me.devEmail.value = client?.email ?? ""
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

		if self.project.developer == nil {

			if let addressBook = ABAddressBook.shared() {

				if let me = addressBook.me() {

					let developer = self.getOrCreateDeveloper()
					developer.firstName = (me.value(forProperty: kABFirstNameProperty) as? String)
					developer.lastName = (me.value(forProperty: kABLastNameProperty) as? String)

					if let allAddresses = me.value(forProperty:kABAddressProperty) as? ABMultiValue {

						let primaryIndex = allAddresses.index(forIdentifier: allAddresses.primaryIdentifier() )
						if primaryIndex != NSNotFound {
							if let address = allAddresses.value(at: primaryIndex) as? NSDictionary {

								developer.address1 = ( address[kABAddressStreetKey] as? String)
								developer.zip = ( address[kABAddressZIPKey] as? String)
								developer.city = ( address[kABAddressCityKey] as? String)
							}
						}
					}

					if let allEmails = me.value(forProperty:kABEmailProperty) as? ABMultiValue {

						let primaryIndex = allEmails.index(forIdentifier: allEmails.primaryIdentifier() )
						if primaryIndex != NSNotFound {
							let email = allEmails.value(at: primaryIndex)
							developer.email = ( email as? String)
						}
					}

					if let allPhones = me.value(forProperty:kABPhoneProperty) as? ABMultiValue {
						let primaryIndex = allPhones.index(forIdentifier: allPhones.primaryIdentifier() )
						if primaryIndex != NSNotFound {
							let phone = allPhones.value(at: primaryIndex)
							developer.phone = ( phone as? String )
						}
					}
				}
			}
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

	private func getOrCreateDeveloper() -> Developer {

		if let developer = self.project.developer {
			return developer
		}

		guard let context = self.project.managedObjectContext else {
			preconditionFailure()
		}

		let developer: Developer = context.insertObject()
		self.project.developer = developer
		return developer
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

	let devFirstName = Property<String>("")
	let devLastName = Property<String>("")
	let devAddress1 = Property<String>("")
	let devAddress2 = Property<String>("")
	let devZIP = Property<String>("")
	let devCity = Property<String>("")
	let devPhone = Property<String>("")
	let devEmail = Property<String>("")

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

	func userWantsSetDevFirstName(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().firstName = string
		})
	}
	func userWantsSetDevLastName(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().lastName = string
		})
	}
	func userWantsSetDevAddress1(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().address1 = string
		})
	}
	func userWantsSetDevAddress2(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().address2 = string
		})
	}
	func userWantsSetDevZIP(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().zip = string
		})
	}
	func userWantsSetDevCity(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().city = string
		})
	}
	func userWantsSetDevPhone(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().phone = string
		})
	}
	func userWantsSetDevEmail(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperationsNoSaving({ context in
			self.getOrCreateDeveloper().email = string
		})
	}

}
