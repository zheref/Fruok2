//
//  TaskStateCollectionItem.swift
//  Fruok
//
//  Created by Matthias Keiser on 09.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class KanbanTaskStateItem: NSCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
		self.view.layer?.backgroundColor = NSColor.red.cgColor
    }
    
}
