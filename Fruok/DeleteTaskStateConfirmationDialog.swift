//
//  DeleteTaskStateConfirmationDialog.swift
//  Fruok
//
//  Created by Matthias Keiser on 14.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class DeleteTaskStateConfirmationDialog: NSViewController, MVVMView {

	@IBOutlet var questionLabel: NSTextField!
	@IBOutlet var deleteButton: NSButton!
	@IBOutlet var assignToButton: NSButton!
	@IBOutlet var stateChoiceButton: NSPopUpButton!

	typealias VIEWMODEL = DeleteTaskStateConfirmationViewModel

	private(set) var viewModel: DeleteTaskStateConfirmationViewModel?
	func set(viewModel: DeleteTaskStateConfirmationViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.connectVMIfReady()
    }


	convenience init() {
		self.init(nibName: "DeleteTaskStateConfirmationDialog", bundle: nil)!
	}
	
	func connectVM() {

		self.viewModel!.deleteChoiceSelected.map{ $0 ? NSOnState : NSOffState}.bind(to: self.deleteButton.reactive.state)
		self.deleteButton.reactive.state.map{ $0 == NSOnState }.bind(to: self) {me, selected in
			self.viewModel?.deleteChoiceSelected.value = selected
			self.viewModel?.assignChoiceSelected.value = !selected
		}

		
		self.viewModel!.assignChoiceSelected.map{ $0 ? NSOnState : NSOffState}.observeNext { state in
			self.assignToButton.state = state
		}.dispose(in: bag)
		self.assignToButton.reactive.state.map{ $0 == NSOnState }.bind(to: self) {me, selected in
			self.viewModel?.assignChoiceSelected.value = selected
			self.viewModel?.deleteChoiceSelected.value = !selected
		}
		self.viewModel!.assignChoiceEnabled.bind(to: self.assignToButton.reactive.isEnabled)

		self.viewModel!.otherStateNames.bind(to: self) { me, titles in

			self.stateChoiceButton.removeAllItems()
			self.stateChoiceButton.addItems(withTitles: titles)
		}

		self.viewModel!.assignChoiceEnabled.bind(to: self.stateChoiceButton.reactive.isEnabled)

		self.stateChoiceButton.reactive.indexOfSelectedItem.observeNext { (index) in
			self.viewModel?.selectedOtherState.value = index
		}.dispose(in: bag)
	}

	@IBAction func okAction(_ sender: Any) {
		self.viewModel?.userDidProceed()
		self.dismiss(nil)
	}
	@IBAction func cancelAction(_ sender: Any) {
		self.viewModel?.userDidProceed()
		self.dismiss(nil)
	}

}
