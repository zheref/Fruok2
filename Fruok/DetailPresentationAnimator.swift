//
//  DetailPresentationAnimator.swift
//  Fruok
//
//  Created by Matthias Keiser on 22.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class DetailPresentationAnimator: NSObject, NSViewControllerPresentationAnimator {

	let presentationViewController = PresentationViewController()

	func animatePresentation(of viewController: NSViewController, from fromViewController: NSViewController) {

		self.presentationViewController.wrappedViewController = viewController
		fromViewController.addChildViewController(self.presentationViewController)

		self.presentationViewController.view.alphaValue = 0.0
		fromViewController.view.tr_addFillingSubview(self.presentationViewController.view)

		if !(self.presentationViewController.view.window?.makeFirstResponder(viewController.view) ?? false) {

			self.presentationViewController.view.window?.makeFirstResponder(self.presentationViewController.view)
		}

		DispatchQueue.main.async { [weak self] in

			NSAnimationContext.runAnimationGroup({ [weak self] context in

				context.duration = 0.5
				self?.presentationViewController.view.animator().alphaValue = 1.0

			}, completionHandler: nil)

		}
	}

	func animateDismissal(of viewController: NSViewController, from fromViewController: NSViewController) {

		NSAnimationContext.runAnimationGroup({ [weak self] context in

			context.duration = 0.5
			self?.presentationViewController.view.animator().alphaValue = 0.0

		}, completionHandler: {

			self.presentationViewController.view.removeFromSuperview()
			self.presentationViewController.removeFromParentViewController()
			self.presentationViewController.wrappedViewController = nil
		})

	}

}
