//
//  StatisticsVC.swift
//  Fruok
//
//  Created by Matthias Keiser on 28.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa
import Charts

class TimeFormatter: NSObject, IAxisValueFormatter, IValueFormatter {

	let formatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .abbreviated
		return formatter
	}()

	func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		if value < 1.0 {
			return ""
		}
		return self.formatter.string(from: value) ?? "???"
	}

	func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
		return self.stringForValue(value, axis: nil)
	}


	static let shared = TimeFormatter()
}

extension NSColor {

	static func chartColorForIndex(_ index: Int) -> NSColor {

		var hue: CGFloat = 0.0

		var powerOf9 = 9

		while true {
			if index < powerOf9 {

				hue = CGFloat(index) * 1.0/CGFloat(powerOf9) + (1.0 / CGFloat(powerOf9))
				break
			}

			powerOf9 *= 9
		}

		return NSColor.init(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 1.0)
	}
}

class StatisticsViewController: NSViewController, MVVMView {

	@IBOutlet var datePicker: NSDatePicker!
	@IBOutlet var tasksPopup: NSPopUpButton!
	@IBOutlet var chartView: BarChartView!
	@IBOutlet var chartViewWidthConstraint: NSLayoutConstraint! // low precedence

	typealias VIEWMODEL = StatisticsViewModel
	private(set) var viewModel: StatisticsViewModel?
	internal func set(viewModel: StatisticsViewModel) {
		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {

		self.init(nibName: "StatisticsVC", bundle: nil)!
	}
	
    override func viewDidLoad() {

		super.viewDidLoad()

		self.chartView.noDataText = NSLocalizedString("No data for the current Selection", comment: "No data for the current Selection")
		self.chartView.noDataTextColor = NSColor.lightGray
		self.chartView.noDataFont = NSFont.systemFont(ofSize: 30)
		self.chartView.minOffset = 50
		self.chartView.chartDescription = nil
		self.chartView.setScaleEnabled(false)
		self.chartView.highlightFullBarEnabled = false
		self.chartView.highlightPerTapEnabled = false

        self.connectVMIfReady()
    }

	func connectVM() {

		self.viewModel?.dateRange.observeNext(with: { [weak self] dateRange in

			self?.datePicker.dateValue = dateRange.date
			self?.datePicker.timeInterval = dateRange.interval

			self?.datePicker.timeInterval = TimeInterval(60 * 60 * 24 * 7)
		}).dispose(in: bag)

		self.viewModel?.taskNames.observeNext(with: { [weak self] (selectedIndex, names) in

			self?.tasksPopup.removeAllItems()
			self?.tasksPopup.addItems(withTitles: names)
			self?.tasksPopup.selectItem(at: selectedIndex)
		}).dispose(in: bag)

		self.viewModel?.chartData.observeNext(with: { [weak self] chartData in

			guard !chartData.isEmpty else {
				self?.chartView.data = nil
				self?.chartViewWidthConstraint.constant = 0
				self?.chartView.notifyDataSetChanged()
				return
			}
			let data = BarChartData()

			let entries = chartData.yValues.enumerated().map { (index, ys) in

				return BarChartDataEntry(x: Double(index), yValues: ys.map { $0 ?? 0.0 })
			}

			let dataSet = BarChartDataSet(values: entries, label: chartData.dataSetLabels.count == 1 ?  chartData.dataSetLabels.first?.name : nil)
			dataSet.stackLabels = chartData.dataSetLabels.map { $0.name }
			dataSet.valueFormatter = TimeFormatter.shared
			dataSet.valueFont = NSFont.systemFont(ofSize: 12)
			dataSet.colors = chartData.dataSetLabels.map { NSColor.chartColorForIndex($0.identifier) }
			data.addDataSet(dataSet)

			self?.chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: chartData.xAxisLabels)
			self?.chartView.xAxis.granularity = 1
			let setupYAxis = { (axis: YAxis?) in
				axis?.granularity = 60
				axis?.axisMinimum = 0
				axis?.axisMaximum = Double((Int(data.yMax / 60) + 10) * 60)
				axis?.valueFormatter = TimeFormatter.shared
			}
			setupYAxis(self?.chartView.leftAxis)
			setupYAxis(self?.chartView.rightAxis)

			if chartData.xAxisLabels.count > 7 {

				self?.chartViewWidthConstraint.constant = CGFloat(max((Double(chartData.xAxisLabels.count) * 50.0), (Double)(self!.chartView.enclosingScrollView!.frame.width)))
			} else {
				self?.chartViewWidthConstraint.constant = 0
			}

			self?.chartView.enclosingScrollView?.reflectScrolledClipView((self?.chartView.enclosingScrollView?.contentView)!)
			self?.chartView.data = data
			//self?.chartView.notifyDataSetChanged()
			self?.chartView.needsDisplay = true
			self?.chartView.displayIfNeeded()
		}).dispose(in: bag)

	}

	
	@IBAction func tasksPopupAction(_ sender: Any) {

		self.viewModel?.userWantsSelectTaskAtIndex(self.tasksPopup.indexOfSelectedItem)
	}

	@IBAction func dateAction(_ sender: Any) {

		let date = self.datePicker.dateValue
		let timeInterval = self.datePicker.timeInterval
		self.viewModel?.userWantsSetDateRange(DateRange(date: date, interval: timeInterval))
	}
}

extension StatisticsViewController: NSDatePickerCellDelegate {

	public func datePickerCell(_ datePickerCell: NSDatePickerCell, validateProposedDateValue proposedDateValue: AutoreleasingUnsafeMutablePointer<NSDate>, timeInterval proposedTimeInterval: UnsafeMutablePointer<TimeInterval>?) {

		let proposedDate = proposedDateValue.pointee as Date
		let proposedInterval = proposedTimeInterval?.pointee ?? 0

		if let (date, interval) = self.viewModel?.userWantsDateRangeValidation((date: proposedDate, timeInterval: proposedInterval)) {

			proposedDateValue.pointee = date as NSDate
			proposedTimeInterval?.pointee = interval
		}
	}
}



