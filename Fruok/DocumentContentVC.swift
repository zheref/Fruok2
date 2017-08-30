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
	@IBOutlet var pomodoroContainerView: NSView!
	@IBOutlet var pomodoroTopConstraint: NSLayoutConstraint!

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

	var currentPomodoroViewController: PomodoroViewController? {
		willSet {
			if let currentPomodoroViewController = self.currentPomodoroViewController {
				currentPomodoroViewController.removeFromParentViewController()
				currentPomodoroViewController.view.removeFromSuperview()
			}
		}
		didSet {
			if let currentPomodoroViewController = self.currentPomodoroViewController {
				self.addChildViewController(currentPomodoroViewController)
				self.pomodoroContainerView.tr_addFillingSubview(currentPomodoroViewController.view)
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
				let controller = StatisticsViewController()
				if let viewModel = self.viewModel?.viewModelForStatistics() {
					controller.set(viewModel: viewModel)
				}
				return controller
			case .billing?:
				return nil
			case nil:
				return nil
			}
		}.bind(to: self) { me, childController in

			me.currentChildViewController = childController
		}

		self.viewModel?.pomodoroVisible.observeNext(with: { [weak self] viewModel in

			if let viewModel = viewModel {
				let controller = PomodoroViewController()
				controller.set(viewModel: viewModel)
				self?.currentPomodoroViewController = controller
				self?.pomodoroTopConstraint.animator().constant = 0

			} else {
				self?.pomodoroTopConstraint.animator().constant = -(self?.pomodoroContainerView.frame.size.height ?? 0)
				self?.currentPomodoroViewController = nil
			}
		}).dispose(in: bag)

		self.viewModel?.sessionCancelConfirmation.observeNext(with: { [weak self] info in

			guard let info = info, let window = (self?.view.window?.parent ?? self?.view.window) else { return }

			let alert = NSAlert()
			alert.alertStyle = .warning
			alert.messageText = info.question
			//			alert.informativeText = info.detailString
			alert.addButton(withTitle: NSLocalizedString("Abort", comment: "Confirm session cancel button"))
			alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel session cancel button"))

			alert.beginSheetModal(for: window, completionHandler: { response in

				if response == NSAlertFirstButtonReturn {
					info.callback()
				}
			})
		}).dispose(in: bag)

	}

	@IBAction func currentChildViewControllerAction(_ sender: NSSegmentedControl?) {

		guard let value = DocumentContentViewModel.ChildView(optionalRawValue: sender?.selectedSegment) else {
			return
		}
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

	@IBAction func startPomodoroSession(_ sender: TaskDetailViewController) {

		if let viewModel = sender.viewModel {
			self.viewModel?.userWantsStartPomodoroSession(for: viewModel)
		}
	}
}

