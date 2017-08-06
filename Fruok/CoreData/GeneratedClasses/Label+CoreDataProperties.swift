//
//  Label+CoreDataProperties.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Label {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Label> {
        return NSFetchRequest<Label>(entityName: "Label");
    }

    @NSManaged public var name: String?
    @NSManaged public var color: LabelColor?
    @NSManaged public var tasks: BaseTask?

}
