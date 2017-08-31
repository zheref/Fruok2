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
}


class PomodoroViewController: NSViewController, MVVMView {

	@IBOutlet var statusLabel: NSTextField!
	@IBOutlet var taskNameLabel: NSTextField!
	@IBOutlet var subtasksPopup: NSPopUpButton!
	@IBOutlet var initialStartButton: NSButton!
	@IBOutlet var startButton: NSButton!
	@IBOutlet var cancelButton: NSButton!

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

	func connectVM() {

		self.viewModel?.subtaskNames.observeNext(with: { [weak self] info in

			self?.subtasksPopup.removeAllItems()
			self?.subtasksPopup.addItems(withTitles: info.names)
			self?.subtasksPopup.selectItem(at: info.selected)
			
		}).dispose(in: bag)

		self.viewModel?.uiState.observeNext(with: { [weak self] uiState in

			self?.startButton.isHidden = !uiState.startNewSessionButtonVisible
			self?.initialStartButton.isHidden = !uiState.initialStartButtonVisisble
			self?.statusLabel.stringValue = uiState.progressLabesString

			let style = NSMutableParagraphStyle()
			style.alignment = .center
			let attrs = [NSFontAttributeName : NSFont.systemFont(ofSize: 13.0), NSForegroundColorAttributeName: NSColor.pomodoroColor, NSParagraphStyleAttributeName: style]

			let cancelString = NSMutableAttributedString(string: uiState.cancelButtonText, attributes:attrs)
			self?.cancelButton.attributedTitle = cancelString

			let startString = NSMutableAttributedString(string: NSLocalizedString("Start", comment: "Start pomodoro button"), attributes:attrs)
			self?.startButton.attributedTitle = startString

		}).dispose(in: bag)

//		self.viewModel?.startButtonVisible.observeNext { [weak self] visible in
//
//			self?.startButton.isHidden = !visible
//		}.dispose(in: bag)
//
//		self.viewModel?.timeString.bind(to: self, setter: { (me, timeString) in
//
//			me.statusLabel.stringValue = timeString
//		})

		self.viewModel?.taskName.observeNext { [weak self] taskName in
			self?.taskNameLabel.stringValue = taskName
		}.dispose(in: bag)

	}

	@IBAction func initialStartAction(_ sender: Any) {
		self.viewModel?.userWantsStartPomodorSession()
	}
	@IBAction func startAction(_ sender: Any) {
		self.viewModel?.userWantsStartPomodorSession()
	}
	@IBAction func subtaskAction(_ sender: Any) {
		self.viewModel?.userWantsChangeSubtask(self.subtasksPopup.indexOfSelectedItem)
	}
	@IBAction func rightAction(_ sender: Any) {

		self.viewModel?.userWantsCancelPomodoroSession()
	}
    
}
