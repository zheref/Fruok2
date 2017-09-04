//
//  SessionFilterViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 30.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

enum PresetPopUpIndex: Int {

	case custom
	case thisWeek
	case lastWeek
	case thisMonth
	case lastMonth
	case thisYear
	case allData
}

extension DateRangePreset {

	var popUpIndex: PresetPopUpIndex {

		switch self {
		case .custom:
			return .custom
		case .thisWeek:
			return .thisWeek
		case .lastWeek:
			return .lastWeek
		case .thisMonth:
			return .thisMonth
		case .lastMonth:
			return .lastMonth
		case .thisYear:
			return .thisYear
		case .allData:
			return .allData
		}
	}

	init(popUpIndex: PresetPopUpIndex, dateRange: DateRange? = nil) {

		switch popUpIndex {
		case .custom:
			self = .custom(dateRange!)
		case .thisWeek:
			self = .thisWeek
		case .lastWeek:
			self = .lastWeek
		case .thisMonth:
			self = .thisMonth
		case .lastMonth:
			self = .lastMonth
		case .thisYear:
			self = .thisYear
		case .allData:
			self = .allData(dateRange!)
		}
	}
}

class SessionFilterViewController: NSViewController, MVVMView {

	@IBOutlet var datePicker: NSDatePicker!
	@IBOutlet var endDatePicker: NSDatePicker!
	@IBOutlet var tasksPopup: NSPopUpButton!
	@IBOutlet var modePopup: NSPopUpButton!
	@IBOutlet var modeLabel: NSTextField!
	@IBOutlet var periodPopUp: NSPopUpButton!

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

		self.viewModel?.selectedDatePreset.observeNext(with: { [weak self] preset in

			self?.periodPopUp.selectItem(at: preset.popUpIndex.rawValue)
			self?.datePicker.dateValue = preset.dateRange.date
			self?.endDatePicker.dateValue = preset.dateRange.endDate

		}).dispose(in: bag)

		self.viewModel?.taskNames.observeNext(with: { [weak self] (selectedIndex, names) in

			self?.tasksPopup.removeAllItems()
			self?.tasksPopup.addItems(withTitles: names)
			self?.tasksPopup.selectItem(at: selectedIndex)
		}).dispose(in: bag)

		self.viewModel?.groupMode.observeNext(with: { [weak self] mode in

			self?.modePopup.selectItem(at: mode.rawValue)

		}).dispose(in: bag)

		self.viewModel?.groupControlVisible.observeNext(with: { [weak self] visible in

			self?.modePopup.isHidden = !visible
			self?.modeLabel.isHidden = !visible
		}).dispose(in: bag)
	}

	@IBAction func tasksPopupAction(_ sender: Any) {

		self.viewModel?.userWantsSelectTaskAtIndex(self.tasksPopup.indexOfSelectedItem)
	}

	@IBAction func groupByAction(_ sender: Any) {
		self.viewModel?.userWantsSetGroupMode(SessionFilterViewModel.GroupMode(rawValue: self.modePopup.indexOfSelectedItem)!)
	}

	@IBAction func dateAction(_ sender: Any) {

		let dateRange = DateRange(startDate: self.datePicker.dateValue, endDate: self.endDatePicker.dateValue)
		self.viewModel?.userWantsSetDateRange(dateRange)
	}

	@IBAction func endDateAction(_ sender: Any) {

		let dateRange = DateRange(startDate: self.datePicker.dateValue, endDate: self.endDatePicker.dateValue)
		self.viewModel?.userWantsSetDateRange(dateRange)

	}
	
	@IBAction func periodPopUpAction(_ sender: Any) {

		guard let popUpIndex = PresetPopUpIndex(rawValue: self.periodPopUp.indexOfSelectedItem) else { return }

		let dateRange: DateRange

		if case .allData = popUpIndex {
			dateRange = self.viewModel?.allDataDateRange() ?? DateRange(startDate: Date().startOfDay, endDate: Date().endOfDay!)
		} else {
			dateRange = DateRange(startDate: self.datePicker.dateValue, endDate: self.endDatePicker.dateValue)
		}
		self.viewModel?.userWantsSetPeriodPreset(DateRangePreset(popUpIndex: popUpIndex, dateRange: dateRange))
	}

	fileprivate var isSettingValidatedDateRange = false
}

extension SessionFilterViewController: NSDatePickerCellDelegate {

	public func datePickerCell(_ datePickerCell: NSDatePickerCell, validateProposedDateValue proposedDateValue: AutoreleasingUnsafeMutablePointer<NSDate>, timeInterval proposedTimeInterval: UnsafeMutablePointer<TimeInterval>?) {

		if self.isSettingValidatedDateRange {
			return
		}
		let dateRange = DateRange(startDate: self.datePicker.dateValue, endDate: self.endDatePicker.dateValue)
		let adjustedRange: DateRange

		if datePickerCell == self.datePicker.cell {
			adjustedRange = self.viewModel?.validateStartDateWithRange(dateRange) ?? dateRange
		} else {
			adjustedRange = self.viewModel?.validateEndDateWithRange(dateRange) ?? dateRange
		}

		self.isSettingValidatedDateRange = true
		self.datePicker.dateValue = adjustedRange.date
		self.endDatePicker.dateValue = adjustedRange.endDate
		self.isSettingValidatedDateRange = false
	}
}
