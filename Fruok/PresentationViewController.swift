//
//  PresentationViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 22.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class PresentationViewController: NSViewController {

	@IBOutlet var scrollEmbeddingView: NSView!
	@IBOutlet var scrollView: NSScrollView!

	var wrappedViewController: NSViewController? {
		willSet {
			if let wrappedController = self.wrappedViewController {
				wrappedController.view.removeFromSuperview()
				wrappedController.removeFromParentViewController()
			}
		}
		didSet {
			if let wrappedController = self.wrappedViewController {
				self.addChildViewController(wrappedController)
			}
			self.positionWrappedView()
		}
	}
	
	convenience init() {
		self.init(nibName: "PresentationViewController", bundle: nil)!
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		(self.view as? PresentationView)?.presentationContoller = self
		self.view.wantsLayer = true
		CATransaction.setDisableActions(true)
		self.view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor
    }

	func positionWrappedView() {

		if let wrappedController = self.wrappedViewController {

			_ = self.view // HACK
			wrappedController.view.frame = CGRect(origin: .zero, size: wrappedController.view.fittingSize)
			wrappedController.view.translatesAutoresizingMaskIntoConstraints = false
			self.scrollView.documentView = wrappedController.view

			let width = NSLayoutConstraint(item: wrappedController.view, attribute: .width, relatedBy: .equal, toItem: self.scrollView.contentView, attribute: .width, multiplier: 1.0, constant: 0)
			width.priority = 100

			let height = NSLayoutConstraint(item: wrappedController.view, attribute: .height, relatedBy: .equal, toItem: self.scrollView.contentView, attribute: .height, multiplier: 1.0, constant: 0)
			height.priority = 100

			self.view.addConstraints([width, height])
			self.view.needsLayout = true
			self.view.layoutSubtreeIfNeeded()
			let scrollPoint = CGPoint(x: 0, y: wrappedController.view.frame.maxY - self.scrollView.bounds.height)
			self.scrollView.contentView.scroll(to: scrollPoint)
			self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
		}
	}

	func receivedPresentationViewEvent() {

		if let wrapped = self.wrappedViewController {
			wrapped.presenting?.dismissViewController(wrapped)
		}
	}

	@IBAction override func cancelOperation(_ sender: Any?) {

		if let wrapped = self.wrappedViewController {
			wrapped.presenting?.dismissViewController(wrapped)
		}
	}

	@IBAction func explicitelyDismiss(_ sender: Any?) {

		if let wrapped = self.wrappedViewController {
			wrapped.presenting?.dismissViewController(wrapped)
		}
	}

    
}

class RoundedRectView: NSView {

	override func draw(_ dirtyRect: NSRect) {

		let rect = NSBezierPath(roundedRect: self.bounds, xRadius: 10, yRadius: 10)
		NSColor.white.set()
		rect.fill()
	}

	override func mouseDown(with event: NSEvent) {

	}
}

class PresentationView: NSView {

	weak var presentationContoller: PresentationViewController?

	override func mouseDown(with event: NSEvent) {

		self.presentationContoller?.receivedPresentationViewEvent()
	}
}
