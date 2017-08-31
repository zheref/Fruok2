//
//  SessionFilterViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 30.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

class SessionFilterViewController: NSViewController, MVVMView {

	@IBOutlet var datePicker: NSDatePicker!
	@IBOutlet var tasksPopup: NSPopUpButton!
	@IBOutlet var modePopup: NSPopUpButton!

	typealias VIEWMODEL = SessionFilterViewModel
	private(set) var viewModel: SessionFilterViewModel?
	internal func set(viewModel: SessionFilterViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {

		self.init(nibName: "SessionFilterVC", bundle: nil)!
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.dateRange.observeNext(with: { [weak self] dateRange in

			self?.datePicker.dateValue = dateRange.date
			self?.datePicker.timeInterval = dateRange.interval

		}).dispose(in: bag)

		self.viewModel?.taskNames.observeNext(with: { [weak self] (selectedIndex, names) in

			self?.tasksPopup.removeAllItems()
			self?.tasksPopup.addItems(withTitles: names)
			self?.tasksPopup.selectItem(at: selectedIndex)
		}).dispose(in: bag)

		self.viewModel?.groupMode.observeNext(with: { [weak self] mode in

			self?.modePopup.selectItem(at: mode.rawValue)

		}).dispose(in: bag)

	}

	@IBAction func tasksPopupAction(_ sender: Any) {

		self.viewModel?.userWantsSelectTaskAtIndex(self.tasksPopup.indexOfSelectedItem)
	}

	@IBAction func groupByAction(_ sender: Any) {
		self.viewModel?.userWantsSetGroupMode(SessionFilterViewModel.GroupMode(rawValue: self.modePopup.indexOfSelectedItem)!)
	}

	@IBAction func dateAction(_ sender: Any) {

		let date = self.datePicker.dateValue
		let timeInterval = self.datePicker.timeInterval
		self.viewModel?.userWantsSetDateRange(DateRange(date: date, interval: timeInterval))
	}
}

extension SessionFilterViewController: NSDatePickerCellDelegate {

	public func datePickerCell(_ datePickerCell: NSDatePickerCell, validateProposedDateValue proposedDateValue: AutoreleasingUnsafeMutablePointer<NSDate>, timeInterval proposedTimeInterval: UnsafeMutablePointer<TimeInterval>?) {

		let proposedDate = proposedDateValue.pointee as Date
		let proposedInterval = proposedTimeInterval?.pointee ?? 0

		if let (date, interval) = self.viewModel?.userWantsDateRangeValidation((date: proposedDate, timeInterval: proposedInterval)) {

			proposedDateValue.pointee = date as NSDate
			proposedTimeInterval?.pointee = interval
		}
	}
}
