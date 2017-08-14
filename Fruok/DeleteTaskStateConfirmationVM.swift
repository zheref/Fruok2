//
//  DeleteTaskStateConfirmationVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 14.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import Bond

class DeleteTaskStateConfirmationViewModel: MVVMViewModel {

	typealias MODEL = TaskState
	let taskState: TaskState

	required init(with model: TaskState) {

		self.taskState = model

		var otherStates: [TaskState] = []
		if let allStates = taskState.project?.taskStates?.array as? [TaskState] {

			otherStates = allStates.filter({ $0 !== model})
			self.otherStateNames.value = otherStates.map({$0.name ?? NSLocalizedString("No Name", comment: "State without name")})
		}

		self.otherStates = otherStates
		self.assignChoiceEnabled.value = self.otherStateNames.value.count > 0
	}

	let otherStates: [TaskState]

	let deleteChoiceSelected = Observable<Bool>(true)
	let assignChoiceSelected = Observable<Bool>(false)
	let assignChoiceEnabled = Observable<Bool>(false)
	let otherStateNames = Observable<[String]>([])
	let selectedOtherState = Observable<Int?>(nil)

	var callback: ((_ didProceed: Bool) -> Void)?

	func userDidCancel() {

		self.callback?(false)
	}
	func userDidProceed() {
		self.callback?(true)
	}
}
