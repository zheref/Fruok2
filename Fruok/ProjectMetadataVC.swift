//
//  ProjectOverviewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 21.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class ProjectMetadataViewController: NSViewController, MVVMView {

	@IBOutlet var projectKindPopup: NSPopUpButton!
	@IBOutlet var codeNameField: NSTextField!
	@IBOutlet var commercialNameField: NSTextField!
	@IBOutlet var durationField: NSTextField!
	@IBOutlet var durationStepper: NSStepper!
	@IBOutlet var deadlinePicker: NSDatePicker!
	@IBOutlet var clientField: NSTextField!


	@IBOutlet var controlsEmbeddingView: NSView!

	typealias VIEWMODEL = ProjectMetadataViewModel
	private(set) var viewModel: ProjectMetadataViewModel?
	func set(viewModel: ProjectMetadataViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {
		self.init(nibName: "ProjectMetadataVC", bundle: nil)!
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		let formatter = NumberFormatter()
		formatter.generatesDecimalNumbers = false
		formatter.maximumFractionDigits = 0
		self.durationField.formatter = formatter

		self.controlsEmbeddingView.wantsLayer = true
		self.controlsEmbeddingView.layer?.backgroundColor = NSColor.white.cgColor
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.codeName.bind(to: self.codeNameField.reactive.stringValue)
		self.viewModel?.commercialName.bind(to: self.commercialNameField.reactive.stringValue)
		self.viewModel?.durationDays.bind(to: self.durationField.reactive.integerValue)
		self.viewModel?.deadline.bind(to: self, context: .immediateOnMain) { (me, date) in

			me.deadlinePicker.dateValue = date ?? Date().addingTimeInterval(30 * 24 * 60 * 60)
		}
		
		self.viewModel?.client.bind(to: self.clientField.reactive.stringValue)

	}

	@IBAction func codeNameAction(_ sender: Any) {
		self.viewModel?.userWantsSetCodeName(self.codeNameField.stringValue)
	}
	@IBAction func commercialNameAction(_ sender: Any) {
		self.viewModel?.userWantsSetCommercialName(self.commercialNameField.stringValue)
	}
	@IBAction func durationAction(_ sender: Any) {
		self.viewModel?.userWantsSetDurationDays(self.durationField.integerValue)
	}
	@IBAction func durationStepperAction(_ sender: Any) {
		self.viewModel?.userWantsSetDurationDays(self.durationStepper.integerValue)
	}
	@IBAction func deadlineAction(_ sender: Any) {
		self.viewModel?.userWantsSetDeadline(self.deadlinePicker.dateValue)
	}
	@IBAction func clientAction(_ sender: Any) {
		self.viewModel?.userWantsSetClient(self.clientField.stringValue)
	}
	@IBAction func projectKindAction(_ sender: Any) {

		if let type = FruokProjectType(rawValue: self.projectKindPopup.indexOfSelectedItem) {
			self.viewModel?.userWantsSetProjectType(type)
		}
	}


}

extension ProjectMetadataViewController: NSTextFieldDelegate {

//	override func controlTextDidEndEditing(_ note: Notification) {
//
//		switch note.object as? NSTextField {
//		case codeNameField?:
//			break
//		case commercialNameField?:
//			break
//		case durationField?:
//			break
//		case clientField?:
//			break
//		default:
//			break
//		}
//	}
}
