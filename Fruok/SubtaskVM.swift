//
//  SubtaskVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 17.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation
import Bond

class SubtaskViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Subtask
	@objc private let subtask: Subtask
	required init(with model: MODEL) {
		self.subtask = model
		super.init()
		self.reactive.keyPath(#keyPath(SubtaskViewModel.subtask.name), ofType: Optional<String>.self, context: .immediateOnMain)
			.map{ name in
				return name ?? NSLocalizedString("Untitled", comment: "Untitled subtask")
			}.bind(to: self.name)
		self.name.bind(to: self, context: .immediateOnMain) { (me, name) in
			me.subtask.name = name
		}
		self.reactive.keyPath(#keyPath(SubtaskViewModel.subtask.done), ofType: Optional<Bool>.self, context: .immediateOnMain).map{$0 ?? false}.bind(to: self.done)
		self.done.bind(to: self, context: .immediateOnMain) { (me, done) in
			me.subtask.done = done
		}
	}

	let name = Observable("")
	let done = Observable(false)
	let editable = Observable(false)

	func userWantsSetSubtaskName(_ name: String) {

		if !name.isEmpty {
			self.subtask.name = name
		}
		self.editable.value = false
	}
}
