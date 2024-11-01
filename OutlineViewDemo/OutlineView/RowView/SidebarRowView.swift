//
//  SidebarRowView.swift
//  OutlineViewDemo
//
//  Created by usagimaru on 2024/11/02.
//

import Cocoa

class SidebarRowView: OutlineRowView {
	
	// 行選択時に青色で強調しない場合は isEmphasized で false を返す（Finder, Music.appスタイル）
	// https://stackoverflow.com/questions/29487687/how-to-remove-nstableviews-border-and-change-cell-selection-color-as-same-as-fi/29490176
	
	override var isEmphasized: Bool {
		get {
			false
		}
		set {}
	}
	
}

