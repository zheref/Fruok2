//
//  InvoiceVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 30.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import WebKit
import Mustache

protocol InvoiceViewPrintDelegate: class {

	func printView(_ view: NSView, sender: Any?)
}

class InvoiceView: FirstResponderView {

	weak var printDelegate: InvoiceViewPrintDelegate?

	@IBAction override func print(_ sender: Any?) {
		self.printDelegate?.printView(self, sender: sender)
	}
}
class InvoiceViewController: NSViewController, MVVMView, InvoiceViewPrintDelegate {

	@IBOutlet var webview: WebView!
	@IBOutlet var filterContainerView: NSView!

	typealias VIEWMODEL = InvoiceViewModel
	private(set) var viewModel: InvoiceViewModel?
	internal func set(viewModel: InvoiceViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	var filterViewController: SessionFilterViewController? {
		willSet {
			if let old = self.filterViewController {
				old.removeFromParentViewController()
				old.view.removeFromSuperview()
			}
		} didSet {
			if let new = self.filterViewController {
				self.addChildViewController(new)
				new.view.translatesAutoresizingMaskIntoConstraints = false
				self.filterContainerView.addSubview(new.view)
				self.filterContainerView.addConstraints( NSLayoutConstraint.tr_fit(new.view))
			}
		}
	}

	convenience init() {
		self.init(nibName: "InvoiceVC", bundle: nil)!
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.filterViewController = SessionFilterViewController()
		(self.view as? InvoiceView)?.printDelegate = self
		self.connectVMIfReady()
	}

	func connectVM() {
		
		self.filterViewController?.set(viewModel: self.viewModel!.sessionFilterViewModel)

		self.viewModel?.htmlInfo.observeNext(with: { [weak self] info in

			if let info = info {
				self?.webview.mainFrame.loadHTMLString(info.htmlString, baseURL: info.baseURL)
			} else {
				self?.webview.mainFrame.loadHTMLString("", baseURL: nil)
			}
		}).dispose(in: bag)

	}

	@IBAction func print(_ sender: Any?) {

		self.webview.print(sender)
	}

	func printView(_ view: NSView, sender: Any?) {
		self.webview.print(sender)
	}

}
