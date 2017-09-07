//
//  Task+CoreDataClass.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(Task)
public class Task: BaseTask {

}

extension Task: ManagedObjectType {

	@nonobjc static let entityName = "Task"
}


extension Task {

	func importAttachments(_ urls: [URL], at index: Int) {

		self.state?.project?.importAttachments(urls, intoTask: (task: self, taskIndex: index))
	}
}
