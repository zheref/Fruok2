//
//  KanbanTaskItemVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 10.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class KanbanTaskItemViewModel: NSObject, MVVMViewModel {

	typealias MODEL = Task
	@objc private let task: Task

	required init(with model: MODEL) {
		self.task = model
		super.init()
	}
}
