//
//  BaseTask+CoreDataProperties.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension BaseTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseTask> {
        return NSFetchRequest<BaseTask>(entityName: "BaseTask");
    }

    @NSManaged public var name: String?
    @NSManaged public var descriptionString: String?
    @NSManaged public var labels: NSSet?

}

// MARK: Generated accessors for labels
extension BaseTask {

    @objc(addLabelsObject:)
    @NSManaged public func addToLabels(_ value: Label)

    @objc(removeLabelsObject:)
    @NSManaged public func removeFromLabels(_ value: Label)

    @objc(addLabels:)
    @NSManaged public func addToLabels(_ values: NSSet)

    @objc(removeLabels:)
    @NSManaged public func removeFromLabels(_ values: NSSet)

}
