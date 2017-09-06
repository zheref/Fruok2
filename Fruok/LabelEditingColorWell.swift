//
//  LabelEditingColorWell.swift
//  Fruok
//
//  Created by Matthias Keiser on 20.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class LabelEditingColorWell: NSColorWell {

	override func draw(_ rect: NSRect) {

		let wellRect = NSInsetRect(rect, 3, 3)
		self.drawWell(inside: wellRect)

		if self.isActive {
			let radius = min(rect.width, rect.height) / 2
			let roundedRect = NSBezierPath.init(roundedRect: rect, xRadius: radius, yRadius: radius)
			roundedRect.setClip()
			roundedRect.lineWidth = 5
			NSColor.black.withAlphaComponent(0.5).set()
			roundedRect.stroke()
			roundedRect.lineWidth = 3
			NSColor.white.withAlphaComponent(0.5).set()
			roundedRect.stroke()
		}
	}
	override func drawWell(inside insideRect: NSRect) {

		let radius = min(insideRect.width, insideRect.height) / 2
		let roundedRect = NSBezierPath.init(roundedRect: insideRect, xRadius: radius, yRadius: radius)
		self.color.set()
		roundedRect.fill()
	}

	override func deactivate() {
		super.deactivate()
		NSColorPanel.shared().orderOut(nil)
	}
}
