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
				me.clientPhone.value = client?.phone ?? ""
				me.clientEmail.value = client?.email ?? ""
			}
		}
	}

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

	let clientFirstName = Property<String>("")
	let clientLastName = Property<String>("")
	let clientAddress1 = Property<String>("")
	let clientAddress2 = Property<String>("")
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



	func userWantsSetClientFirstName(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperations({ context in
			self.getOrCreateClient().firstName = string
		})
	}
	func userWantsSetClientLastName(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperations({ context in
			self.getOrCreateClient().lastName = string
		})
	}
	func userWantsSetClientAddress1(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperations({ context in
			self.getOrCreateClient().address1 = string
		})
	}
	func userWantsSetClientAddress2(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperations({ context in
			self.getOrCreateClient().address2 = string
		})
	}
	func userWantsSetClientPhone(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperations({ context in
			self.getOrCreateClient().phone = string
		})
	}
	func userWantsSetClientEmail(_ string: String) {
		self.project.managedObjectContext?.undoGroupWithOperations({ context in
			self.getOrCreateClient().email = string
		})
	}
}
