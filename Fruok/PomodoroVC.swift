//
//  PomodoroViewController.swift
//  Fruok
//
//  Created by Matthias Keiser on 27.08.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Cocoa

extension NSColor {

	static var pomodoroColor: NSColor {


		return #colorLiteral(red: 1, green: 0.3409153521, blue: 0.2826497555, alpha: 1)
	}
	static var pomodoroPauseColor: NSColor {

		return #colorLiteral(red: 0.3389132619, green: 0.8758600354, blue: 0.3954921067, alpha: 1)
	}

	static func colorForPomodoroColor(_ color: PomodoroViewModel.UIState.Color) -> NSColor {

		switch color {
		case .pomodoro:
			return NSColor.pomodoroColor
		case .pause:
			return NSColor.pomodoroPauseColor
		}
	}
}


class PomodoroViewController: NSViewController, MVVMView {

	@IBOutlet var statusLabel: NSTextField!
	@IBOutlet var taskDescriptionLabel: NSTextField!
	@IBOutlet var subtaskDescriptionLabel: NSTextField!
	@IBOutlet var taskNameLabel: NSTextField!
	@IBOutlet var subtasksPopup: NSPopUpButton!
	@IBOutlet var initialStartButton: NSButton!
	@IBOutlet var startButton: NSButton!
	@IBOutlet var cancelButton: NSButton!
	@IBOutlet var takeABreakLabel: NSTextField!

	typealias VIEWMODEL = PomodoroViewModel
	private(set) var viewModel: PomodoroViewModel?
	internal func set(viewModel: PomodoroViewModel) {

		self.viewModel = viewModel
		self.connectVMIfReady()
	}

	convenience init() {
		self.init(nibName: "PomodoroVC", bundle: nil)!
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.wantsLayer = true
		self.view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor

		self.connectVMIfReady()
    }

	func applyControlState(
		_ control: NSControl,
		state: PomodoroViewModel.UIState.TextControlState,
		fontSize: CGFloat,
		color: NSColor,
		alignment: NSTextAlignment,
		image: NSImage?) {

		guard case let .visible(string) = state else {
			control.isHidden = true
			return
		}

		control.isHidden = false

		let style = NSMutableParagraphStyle()
		style.alignment = alignment
		let attrs = [NSFontAttributeName : NSFont.systemFont(ofSize: fontSize), NSForegroundColorAttributeName: color, NSParagraphStyleAttributeName: style]
		let attrString = NSMutableAttributedString(string: string, attributes:attrs)

		if let label = control as? NSTextField {

			label.attributedStringValue = attrString
		} else if let button = control as? NSButton {

			button.attributedTitle = attrString
			button.image = image
		}
	}

	func connectVM() {

		self.viewModel?.subtaskNames.observeNext(with: { [weak self] info in

			self?.subtasksPopup.removeAllItems()
			self?.subtasksPopup.addItems(withTitles: info.names)
			self?.subtasksPopup.selectItem(at: info.selected)
			
		}).dispose(in: bag)

		self.viewModel?.uiState.observeNext(with: { [weak self] uiState in

			guard let myself = self else {return}

			let color = NSColor.colorForPomodoroColor(uiState.color)

			var image: NSImage = {if case .pomodoro = uiState.color { return #imageLiteral(resourceName: "StartPomodoro") } else { return #imageLiteral(resourceName: "StartPomodoroBreak")} }()
			myself.applyControlState(myself.startButton, state: uiState.startButton, fontSize: 13.0, color: color, alignment: .center, image: image)

			image = {if case .pomodoro = uiState.color { return #imageLiteral(resourceName: "StopPomodoro") } else { return #imageLiteral(resourceName: "StopPomodoroBreak") } }()
			myself.applyControlState(myself.cancelButton, state: uiState.cancelButton, fontSize: 13.0, color: color, alignment: .center, image: image)

			myself.applyControlState(myself.statusLabel, state: uiState.progressLabel, fontSize: 69.0, color: color, alignment: .center, image: nil)

			myself.subtaskDescriptionLabel.isHidden = !uiState.taskInfoVisible
			myself.subtasksPopup.isHidden = !uiState.taskInfoVisible
			myself.taskNameLabel.isHidden = !uiState.taskInfoVisible
			myself.taskDescriptionLabel.isHidden = !uiState.taskInfoVisible

			myself.takeABreakLabel.isHidden = !uiState.takeBreakLabelVisible

			myself.taskNameLabel.textColor = color
			myself.taskDescriptionLabel.textColor = color
			myself.subtaskDescriptionLabel.textColor = color
			myself.takeABreakLabel.textColor = color

		}).dispose(in: bag)

		self.viewModel?.taskName.observeNext { [weak self] taskName in
			self?.taskNameLabel.stringValue = taskName
		}.dispose(in: bag)

	}

	@IBAction func startAction(_ sender: Any) {
		self.viewModel?.userWantsStart()
	}
	@IBAction func subtaskAction(_ sender: Any) {
		self.viewModel?.userWantsChangeSubtask(self.subtasksPopup.indexOfSelectedItem)
	}
	@IBAction func cancelAction(_ sender: Any) {

		self.viewModel?.userWantsCancel()
	}
    
}
