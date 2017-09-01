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

	@IBOutlet var clientFirstNameField: NSTextField!
	@IBOutlet var clientLastNameField: NSTextField!
	@IBOutlet var clientAddress1Field: NSTextField!
	@IBOutlet var clientAddress2Field: NSTextField!
	@IBOutlet var clientPhoneField: NSTextField!
	@IBOutlet var clientEmailField: NSTextField!

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

		self.viewModel?.clientFirstName.bind(to: self.clientFirstNameField.reactive.stringValue)
		self.viewModel?.clientLastName.bind(to: self.clientLastNameField.reactive.stringValue)
		self.viewModel?.clientAddress1.bind(to: self.clientAddress1Field.reactive.stringValue)
		self.viewModel?.clientAddress2.bind(to: self.clientAddress2Field.reactive.stringValue)
		self.viewModel?.clientPhone.bind(to: self.clientPhoneField.reactive.stringValue)
		self.viewModel?.clientEmail.bind(to: self.clientEmailField.reactive.stringValue)

	}

	@IBAction func projectKindAction(_ sender: Any) {

		if let type = FruokProjectType(rawValue: self.projectKindPopup.indexOfSelectedItem) {
			self.viewModel?.userWantsSetProjectType(type)
		}
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

	@IBAction func clientFirstNameAction(_ sender: NSTextField) {
		self.viewModel?.userWantsSetClientFirstName(sender.stringValue)
	}
	@IBAction func clientLastNameAction(_ sender: NSTextField) {
		self.viewModel?.userWantsSetClientLastName(sender.stringValue)
	}
	@IBAction func clientAddress1Action(_ sender: NSTextField) {
		self.viewModel?.userWantsSetClientAddress1(sender.stringValue)
	}
	@IBAction func clientAddress2Action(_ sender: NSTextField) {
		self.viewModel?.userWantsSetClientAddress2(sender.stringValue)
	}
	@IBAction func clientPhoneAction(_ sender: NSTextField) {
		self.viewModel?.userWantsSetClientPhone(sender.stringValue)
	}
	@IBAction func clientEmailAction(_ sender: NSTextField) {
		self.viewModel?.userWantsSetClientEmail(sender.stringValue)
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
