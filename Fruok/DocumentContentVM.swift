//
//  DocumentContentVM.swift
//  Fruok
//
//  Created by Matthias Keiser on 07.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation


class DocumentContentViewModel: NSObject {

	public enum ChildView {
		case kanban
	}

	public private(set) var currentChildView: ChildView? = .kanban
}
