//
//  LabelColor+CoreDataProperties.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension LabelColor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LabelColor> {
        return NSFetchRequest<LabelColor>(entityName: "LabelColor");
    }

    @NSManaged public var label: Label?

}
