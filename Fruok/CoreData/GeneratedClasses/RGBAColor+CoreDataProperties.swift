//
//  RGBAColor+CoreDataProperties.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension RGBAColor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RGBAColor> {
        return NSFetchRequest<RGBAColor>(entityName: "RGBAColor");
    }

    @NSManaged public var r: Double
    @NSManaged public var g: Double
    @NSManaged public var b: Double
    @NSManaged public var a: Double
}
