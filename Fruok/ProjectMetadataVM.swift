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

		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.client), ofType: Optional<String>.self, context: .immediateOnMain)
			.map { $0 ?? NSLocalizedString("No Client", comment: "No Client")}
			.bind(to: self.client)
		self.reactive.keyPath(#keyPath(ProjectMetadataViewModel.project.kind), ofType: Optional<Int>.self, context: .immediateOnMain)
			.map { FruokProjectType(optionalRawValue: $0) ?? .software}
			.bind(to: self.type)

	}

	let type = Property<FruokProjectType>(.software)
	let codeName = Property<String>("")
	let commercialName = Property<String>("")
	let durationDays = Property<Int>(0)
	let deadline = Property<Date?>(nil)
	let client = Property<String>("")

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
	func userWantsSetClient(_ client: String) {
		self.project.client = client
	}
}
