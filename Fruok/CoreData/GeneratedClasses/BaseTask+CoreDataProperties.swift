//
//  BaseTask+CoreDataProperties.swift
//  
//
//  Created by Matthias Keiser on 19.08.17.
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

}
