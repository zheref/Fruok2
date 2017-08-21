//
//  ViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 06.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Bond

extension DocumentContentViewModel.ChildView {

	public enum ChildViewIdentifier: String {
		case project
		case kanban
		case statistics
		case billing
	}

	var storyboardIdentifier: String {

		switch self {
		case .project:
			return "none"
		case .kanban:
			return ChildViewIdentifier.kanban.rawValue
		case .statistics:
			return ChildViewIdentifier.statistics.rawValue
		case .billing:
			return ChildViewIdentifier.billing.rawValue
		}
	}
}
class DocumentContentViewController: NSViewController, MVVMView {

	typealias VIEWMODEL = DocumentContentViewModel
	private(set) var viewModel: DocumentContentViewModel?
	internal func set(viewModel: DocumentContentViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	@IBOutlet var containerView: NSView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	var currentChildViewController: NSViewController? {
		willSet {
			if let currentChildViewController = self.currentChildViewController {
				currentChildViewController.removeFromParentViewController()
				currentChildViewController.view.removeFromSuperview()
			}
		}
		didSet {
			if let currentChildViewController = self.currentChildViewController {
				self.addChildViewController(currentChildViewController)
				self.containerView.tr_addFillingSubview(currentChildViewController.view)
			}
			self.view.window?.toolbar?.validateVisibleItems()
		}
	}

	func connectVM() {

		self.viewModel?.currentChildView.map { (childIdentifier) -> NSViewController? in

			switch childIdentifier {
			case .project?:
				let controller = ProjectMetadataViewController()
				if let viewModel = self.viewModel?.viewModelForProjectMetadata() {
					controller.set(viewModel: viewModel)
				}
				return controller
			case .kanban?:
				let controller = self.storyboard?.instantiateController(withIdentifier: DocumentContentViewModel.ChildView.kanban.storyboardIdentifier) as! KanbanViewController
				if let viewModel = self.viewModel?.viewModelForKanBan() {
					controller.set(viewModel: viewModel)
				}
				return controller
			case .statistics?:
				return nil
			case .billing?:
				return nil
			case nil:
				return nil
			}
		}.bind(to: self) { me, childController in

			me.currentChildViewController = childController
		}
	}

	@IBAction func currentChildViewControllerAction(_ sender: NSSegmentedControl?) {

		let value = DocumentContentViewModel.ChildView(optionalRawValue: sender?.selectedSegment)
		self.viewModel?.changeCurrentChildView(to: value)
	}

	enum ToolbarItemIdentifier: String {
		case view
	}
	override func validateToolbarItem(_ item: NSToolbarItem) -> Bool {

		switch ToolbarItemIdentifier(rawValue: item.itemIdentifier) {
		case .view?:
			(item.view as! NSSegmentedControl).selectedSegment = self.viewModel?.currentChildView.value?.rawValue ?? 0
			return true
		default:
			return super.validateToolbarItem(item)
		}
	}
}

