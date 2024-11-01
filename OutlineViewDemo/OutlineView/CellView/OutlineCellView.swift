//
//  OutlineCellView.swift
//
//  Created by usagimaru on 2021/09/07.
//

import Cocoa
import NibInstantiater

class OutlineCellView: NSTableCellView, NibInstantiatable {
	
	@IBOutlet var iconView: NSImageView!
	
	private var observations = Notify()
	
	override func prepareForReuse() {
		super.prepareForReuse()
		// 前の内容を消去
		self.textField?.stringValue = ""
		self.imageView?.image = nil
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		observations.receive(NSWindow.didBecomeKeyNotification, sender: self.window) { [weak self] notification in
			self?.updateAppearance(window: self?.window)
			self?.needsDisplay = true
		}
		observations.receive(NSWindow.didResignKeyNotification, sender: self.window) { [weak self] notification in
			self?.updateAppearance(window: self?.window)
			self?.needsDisplay = true
		}
		observations.receive(NSWindow.didChangeBackingPropertiesNotification, sender: self.window) { [weak self] notification in
			self?.updateAppearance(window: self?.window)
			self?.needsDisplay = true
		}
	}
	
	/// セルの内容を設定し反映
	override var objectValue: Any? { didSet {
		if let item = objectValue as? OutlineColumnItem {
			textField?.stringValue = item.title ?? ""
			iconView?.image = item.image
		}
	}}
	
	func setSecondaryAppearance() {
		textField?.textColor = .secondaryLabelColor
	}
	
	func setDefaultAppearance() {
		textField?.textColor = .labelColor
	}
	
	func updateAppearance(window: NSWindow?) {
		guard let _ = superview(whichIs: NSTableRowView.self)
		else {return}
		
		//print(#function, "\(rowView.isEmphasized)")
		
		if (window?.isKeyWindow ?? false) == true {
			iconView.contentTintColor = .controlAccentColor
		}
		else {
			iconView.contentTintColor = .disabledControlTextColor
		}
	}
	
}
