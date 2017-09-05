//
//  Attachment+CoreDataClass.swift
//  
//
//  Created by Matthias Keiser on 22.08.17.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(Attachment)
public class Attachment: NSManagedObject {

}

extension Attachment: ManagedObjectType {

	@nonobjc static let entityName = "Attachment"
}

extension Attachment {

	var fileURL: URL? {

		guard let fruokDocumentContext = self.managedObjectContext as? FruokDocumentObjectContext else {
			return nil
		}

		guard let contextDelegate = fruokDocumentContext.delegate else {
			return nil
		}

		return contextDelegate.context(fruokDocumentContext, urlForExistingAttachmentWithIdentifier: self.identifier, name: self.filename)
	}

	var name: String? {

		return self.fileURL?.lastPathComponent
	}
}
