//
//  ContentViewController.swift
//  OutlineViewDemo
//
//  Created by usagimaru on 2024/11/02.
//

import Cocoa

class ContentViewController: OutlineViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
	
	override func setupOutlineView() {
		super.setupOutlineView()
		
		// 縦ドラッグで選択
		outlineView.verticalMotionCanBeginDrag = false
	}
	
	override func makeItemTree() {
		// Sample:
		
		let itemIcon = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
		let folderIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
		let rootIcon = NSImage(systemSymbolName: "house", accessibilityDescription: nil)
		
		rootSidebarItem = .init {
			[
				OutlineFolderItem({
					[
						OutlineFolderItem({
							[
								OutlineFolderItem({
									[
										OutlineItem(columnItems: [
											OutlineColumnItem(title: "Item a", image: itemIcon),
											OutlineColumnItem(title: "column 2"),
										]),
										OutlineItem(columnItems: [
											OutlineColumnItem(title: "Item b", image: itemIcon),
											OutlineColumnItem(title: "column 2"),
										]),
									]
								}, title: "Folder A", image: folderIcon),
								OutlineFolderItem({
									[
										OutlineItem(columnItems: [
											OutlineColumnItem(title: "Item 0", image: itemIcon),
											OutlineColumnItem(title: "column 2"),
										]),
										OutlineItem(columnItems: [
											OutlineColumnItem(title: "Item 1", image: itemIcon),
											OutlineColumnItem(title: "column 2"),
										]),
										OutlineItem(columnItems: [
											OutlineColumnItem(title: "Item 2", image: itemIcon),
											OutlineColumnItem(title: "column 2"),
										]),
									]
								}, title: "Folder B", image: folderIcon),
							]
						}, title: "Folder 0", image: folderIcon),
						OutlineFolderItem({
							[
								OutlineItem(columnItems: [
									OutlineColumnItem(title: "Item α", image: itemIcon),
									OutlineColumnItem(title: "column 2"),
								]),
								OutlineItem(columnItems: [
									OutlineColumnItem(title: "Item β", image: itemIcon),
									OutlineColumnItem(title: "column 2"),
								]),
								OutlineItem(columnItems: [
									OutlineColumnItem(title: "Item γ", image: itemIcon),
									OutlineColumnItem(title: "column 2"),
								]),
							]
						}, title: "Folder 1", image: folderIcon),
						OutlineItem(columnItems: [
							OutlineColumnItem(title: "Item あ", image: itemIcon),
							OutlineColumnItem(title: "column 2"),
						]),
						OutlineItem(columnItems: [
							OutlineColumnItem(title: "Item い", image: itemIcon),
							OutlineColumnItem(title: "column 2"),
						]),
						OutlineItem(columnItems: [
							OutlineColumnItem(title: "Item う", image: itemIcon),
							OutlineColumnItem(title: "column 2"),
						]),
						OutlineItem(columnItems: [
							OutlineColumnItem(title: "Item え", image: itemIcon),
							OutlineColumnItem(title: "column 2"),
						]),
						OutlineItem(columnItems: [
							OutlineColumnItem(title: "Item お", image: itemIcon),
							OutlineColumnItem(title: "column 2"),
						]),
					]
				}, title: "Root", image: rootIcon)
			]
		}
		
		outlineView.reloadData()
		outlineView.expandItem(nil, expandChildren: true)
	}
	
	override func prepareForDragging(_ outlineView: NSOutlineView, validateDrop draggingInfo: NSDraggingInfo, proposedItem parentItem: Any?, proposedChildIndex index: Int) {
		// ドロップ表示のスタイル
		outlineView.draggingDestinationFeedbackStyle = .regular // インジケータ表示スタイル
		//outlineView.draggingDestinationFeedbackStyle = .gap // Source List用
		//outlineView.draggingDestinationFeedbackStyle = .sourceList // Source List用
		
		// ドロップ時アニメーション（使い方がわからない）
		draggingInfo.animatesToDestination = false
		//draggingInfo.animatesToDestination = true
		
		// ドラッグ中の表示形態
		draggingInfo.draggingFormation = .list // リスト
		//draggingInfo.draggingFormation = .stack // 積み重ね
		//draggingInfo.draggingFormation = .pile // ランダムに角度がついて重なる
	}
	
}
