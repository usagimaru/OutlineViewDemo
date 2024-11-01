//
//  SidebarViewController.swift
//  OutlineViewDemo
//
//  Created by usagimaru on 2024/11/02.
//

import Cocoa

class SidebarViewController: OutlineViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func setupOutlineView() {
		super.setupOutlineView()
		
		inhibitsEmphasizedSelectionColor = true
	}
	
	override func makeItemTree() {
		// Sample:
		
		let itemIcon = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
		let folderIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
		
		rootSidebarItem = .init {
			[
				OutlineGroupSectionItem({
					[
						OutlineFolderItem({
							[
								OutlineItem(title: "Item 0", image: itemIcon),
								OutlineItem(title: "Item 1", image: itemIcon),
								OutlineItem(title: "Item 2", image: itemIcon),
								OutlineItem(title: "Item 3", image: itemIcon),
							]
						}, title: "Folder A", image: folderIcon),
						OutlineFolderItem({
							[]
						}, title: "Folder B", image: folderIcon),
						OutlineFolderItem({
							[]
						}, title: "Folder C", image: folderIcon),
					]
				}, title: "Frist Section"),
				OutlineGroupSectionItem({
					[
						OutlineItem(title: "Item あ", image: itemIcon),
						OutlineItem(title: "Item い", image: itemIcon),
						OutlineItem(title: "Item う", image: itemIcon),
						OutlineFolderItem({
							[]
						}, title: "Folder A", image: folderIcon),
						OutlineFolderItem({
							[]
						}, title: "Folder B", image: folderIcon),
						OutlineFolderItem({
							[]
						}, title: "Folder C", image: folderIcon),
					]
				}, title: "Second Section"),
				OutlineGroupSectionItem({
					[]
				}, title: "よく使う項目"),
				OutlineGroupSectionItem({
					[]
				}, title: "iCloud"),
				OutlineGroupSectionItem({
					[]
				}, title: "このMac内"),
			]
		}
		
		outlineView.reloadData()
		outlineView.expandItem(nil, expandChildren: true)
	}
	
	override func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
		guard let item = item as? OutlineItem else { return nil }
		
		// 背景色をグレーに固定する
		let rowView = SidebarRowView()
		
		if item is OutlineGroupSectionItem {
			rowView.identifier = item.rowViewIdentifier() ?? NSUserInterfaceItemIdentifier(CellIdentifier.sectionHeader.rawValue)
		}
		else {
			rowView.identifier = item.rowViewIdentifier() ?? NSUserInterfaceItemIdentifier(CellIdentifier.standardRow.rawValue)
		}
		
		return rowView
	}
	
	override func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		if item is OutlineGroupSectionItem {
			let cellViewIdentifier = NSUserInterfaceItemIdentifier(CellIdentifier.sectionHeader.rawValue)
			let cellView = SourceListHeaderView.loadUnownedNib()
			cellView.identifier = cellViewIdentifier
			cellView.objectValue = item
			return cellView
		}
		
		return super.outlineView(outlineView, viewFor: tableColumn, item: item)
	}
	
	override func prepareForDragging(_ outlineView: NSOutlineView, validateDrop draggingInfo: NSDraggingInfo, proposedItem parentItem: Any?, proposedChildIndex index: Int) {
		// ドロップ表示のスタイル
		//outlineView.draggingDestinationFeedbackStyle = .regular // インジケータ表示スタイル
		outlineView.draggingDestinationFeedbackStyle = .gap // Source List用
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

