//
//  SourceListHeaderView.swift
//
//  Created by usagimaru on 2020/05/23.
//  Copyright © 2020 usagimaru. All rights reserved.
//

import Cocoa
import NibInstantiater

class SourceListHeaderView: NSTableCellView, NibInstantiatable {
	
	/// セルの内容を設定し反映
	override var objectValue: Any? { didSet {
		if let item = objectValue as? OutlineColumnItem {
			textField?.stringValue = item.title ?? ""
		}
		else if let item = objectValue as? OutlineGroupSectionItem {
			textField?.stringValue = item.columnItems.first?.title ?? ""
		}
	}}
	
}
