//
//  BaseTask+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 10.08.17.
//
//

import Foundation
import CoreData


extension BaseTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseTask> {
        return NSFetchRequest<BaseTask>(entityName: "BaseTask");
    }

    @NSManaged public var descriptionString: NSAttributedString?
    @NSManaged public var name: String?
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
