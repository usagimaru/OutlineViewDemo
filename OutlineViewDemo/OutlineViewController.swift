//
//  OutlineViewController.swift
//  OutlineViewDemo
//
//  Created by usagimaru on 2024/11/02.
//

import Cocoa

private extension NSPasteboard.PasteboardType {
	
	/// Dragging Type
	static let sidebarItemDraggingType: NSPasteboard.PasteboardType = .init("jp.usagimaru.DraggingType.OutlineItem")
	
}

class OutlineViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
	
	@IBOutlet var outlineView: NSOutlineView!
	
	/// アイテム情報の構造体
	struct ItemInfo {
		var item: OutlineItem
		var parent: OutlineItem?
		var index: Int
	}
	
	/// ドラッグ中アイテム情報の構造体
	struct DraggingItemInfo {
		var itemInfo = [ItemInfo]()
		var newParent: OutlineItem?
		var insertionIndex: Int
		var isContinuous = [UUID : Bool]()
		
		mutating func addItem(_ item: OutlineItem, parent: OutlineItem?, index: Int) {
			itemInfo.append(ItemInfo(item: item, parent: parent, index: index))
		}
		
		func itemInfo(for itemIdentifier: UUID) -> ItemInfo? {
			itemInfo.first { $0.item.itemIdentifier == itemIdentifier }
		}
		
		func itemInfo(of parent: OutlineItem) -> [ItemInfo] {
			itemInfo.filter { $0.parent == parent }
		}
		
		func items() -> [OutlineItem] {
			itemInfo.map { $0.item }
		}
	}
	
	/// アイテムの状態を一時保存する構造体
	struct ItemStateInfo {
		var item: OutlineItem
		var isExpanded: Bool
		var isSelected: Bool
	}
	
	/// サイドバーアイテムのツリー
	var rootSidebarItem = OutlineItem()
	/// ドラッグ中アイテム情報の構造体
	var draggingItemInfo: DraggingItemInfo?
	/// アイテムの状態を一時保存する構造体
	var itemStateInfo = [ItemStateInfo]()
	/// 永続化可能なツリーの並び順情報
	var sidebarOrder: OutlineOrder?
	
	var inhibitsEmphasizedSelectionColor: Bool = false
	
	
	// MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// アウトラインビューを設定
		setupOutlineView()
		
		// ツリーを用意
		makeItemTree()
		restoreItemOrders()
	}
	
	
	// MARK: -
	
	/// アウトラインビューを設定
	func setupOutlineView() {
		outlineView.dataSource = self
		outlineView.delegate = self
		outlineView.usesAutomaticRowHeights = true
		outlineView.stronglyReferencesItems = false
		outlineView.verticalMotionCanBeginDrag = true
		outlineView.allowsMultipleSelection = true
		outlineView.registerForDraggedTypes([.sidebarItemDraggingType])
		
		// Interface BuilderからAutosaveNameを設定するとなぜかうまく機能しない。コード側から両プロパティを設定すると動作するようになる
		// https://stackoverflow.com/questions/25789554/autosave-expanded-items-of-nsoutlineview-doesnt-work/46233459
		// outlineView.autosaveName = "OutlineView"
		// outlineView.autosaveExpandedItems = true
		
		outlineView.register(OutlineCellView.nib(), forIdentifier: NSUserInterfaceItemIdentifier(CellIdentifier.standardCell.rawValue))
		outlineView.register(SeparatorRowView.nib(), forIdentifier: NSUserInterfaceItemIdentifier(CellIdentifier.separatorRow.rawValue))
		
		// 他のアプリケーションからのドラッグを無効化
		outlineView.setDraggingSourceOperationMask(NSDragOperation(), forLocal: false)
		// アプリケーション内でのドラッグ有効化
		outlineView.setDraggingSourceOperationMask(.every, forLocal: true)
	}
	
	func makeItemTree() {
		outlineView.reloadData()
		outlineView.expandItem(nil, expandChildren: true)
	}
	
	func restoreItemOrders() {
		// 可能なら並び順を復元して反映
		if let sidebarOrder {
			rootSidebarItem.reflectOrdersToItemTree(sidebarOrder)
		}
		else {
			sidebarOrder = rootSidebarItem.newOrder()
		}
	}
	
	
	// MARK: - NSPasteboardItemDataProvider
	
	func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
		
	}
	
	
	// MARK: -
	
	func selectedItems() -> [OutlineItem] {
		outlineView.selectedRowIndexes.map { row in
			outlineView.item(atRow: row)
		}.compactMap { $0 as? OutlineItem }
	}
	
	
	// MARK: -
	
	/// データソースを更新
	func updateDataSource(_ draggingItemInfo: DraggingItemInfo) {
		let draggedItems = draggingItemInfo.items()
		if draggedItems.isEmpty { return }
		
		let newParentObject = draggingItemInfo.newParent ?? rootSidebarItem
		let newInsertion = draggingItemInfo.insertionIndex
		
		//print(#function, "A: new parent: \(newParentObject.title ?? "") count: \(newParentObject.children.count) dragging: \(draggedItems.count) insertion: \(newInsertion)")
		
		draggedItems.forEach {
			// 新しい親に元から所属していないアイテムは、現親から削除する
			if newParentObject.children.contains($0) == false {
				$0.removeFromParent()
			}
		}
		
		// 新しい親の指定位置に挿入
		newParentObject.insertOrMoveChildren(draggedItems, to: newInsertion)
		
		//print(#function, "B: new parent: \(newParentObject.title ?? "") count: \(newParentObject.children.count) dragging: \(draggedItems.count) insertion: \(newInsertion)")
	}
	
	/// OutlineViewの表示を更新して、挿入先情報を返す
	func displayOutlineView(_ draggingItemInfo: DraggingItemInfo) -> ItemInfo? {
		var insertionParentItem: ItemInfo?
		
		if draggingItemInfo.itemInfo.isEmpty { return nil }
		
		let newParentItem = (draggingItemInfo.newParent == rootSidebarItem) ? nil : draggingItemInfo.newParent
		var insertionIndex = draggingItemInfo.insertionIndex
		let firstItemIndex = draggingItemInfo.itemInfo.sorted {
			$0.index < $1.index
		}.first?.index ?? 0
		
//		outlineView.beginUpdates()
		
		/// FIXME: インデックスがズレる条件がある
		for itemInfo in draggingItemInfo.itemInfo.reversed() {
			let isRoot = itemInfo.parent?.isRoot ?? false
			let oldParentItem = isRoot == true ? nil : itemInfo.parent
			
//			if newParentItem == oldParentItem
//			if draggingItemInfo.itemInfo.count > 1 && draggingItemInfo.itemInfo.first?.index ?? 0 > insertionIndex {
//				insertionIndex -= 1
//			}
			
			if newParentItem == oldParentItem && firstItemIndex < insertionIndex {
				insertionIndex -= 1
			}
			
			moveItem(at: itemInfo.index,
					 inParent: oldParentItem,
					 to: insertionIndex,
					 inParent: newParentItem)
		}
		
//		outlineView.endUpdates()
		
		insertionParentItem = ItemInfo(item: newParentItem ?? rootSidebarItem,
									   parent: newParentItem?.parent ?? rootSidebarItem,
									   index: insertionIndex)
		
		return insertionParentItem
	}
	
	/// ビューの再表示を行う
	func reload(with draggingItemInfo: DraggingItemInfo) {
		//outlineView.beginUpdates()
		if let insertionItem = displayOutlineView(draggingItemInfo)?.item {
			//outlineView.beginUpdates()
			
			// ドロップ先をリロードして、必要ならディスクロージャを表示
			// 表示がおかしくなるのでchildrenをリロードしてはいけない
			reloadItem(insertionItem, reloadChildren: false)
			
			// ドラッグ元をリロードして、必要ならディスクロージャを非表示
			draggingItemInfo.itemInfo.forEach { itemInfo in
				if let oldParent = itemInfo.parent, oldParent.children.isEmpty {
					// 表示がおかしくなるのでchildrenをリロードしてはいけない
					reloadItem(oldParent, reloadChildren: false)
				}
			}
			//outlineView.endUpdates()
		}
		
		//outlineView.endUpdates()
	}
	
	
	// MARK: -
	
	func moveItem(at: Int, inParent fromParent: OutlineItem?, to: Int, inParent toParent: OutlineItem?) {
		let fromParent = (fromParent == rootSidebarItem) ? nil : fromParent
		let toParent = (toParent == rootSidebarItem) ? nil : toParent
		
		outlineView.moveItem(at: at,
							 inParent: fromParent,
							 to: to,
							 inParent: toParent)
	}
	
	func moveItem2(at: Int, inParent fromParent: OutlineItem?, deleteAnimation: NSTableView.AnimationOptions = .slideUp,
						   to: Int, inParent toParent: OutlineItem?, insertionAnimation: NSTableView.AnimationOptions = .slideDown) {
		let fromParent = (fromParent == rootSidebarItem) ? nil : fromParent
		let toParent = (toParent == rootSidebarItem) ? nil : toParent
		
		outlineView.removeItems(at: IndexSet(integer: at),
								inParent: fromParent,
								withAnimation: deleteAnimation)
		outlineView.insertItems(at: IndexSet(integer: to),
								inParent: toParent,
								withAnimation: insertionAnimation)
	}
	
	func reloadItem(_ item: OutlineItem?, reloadChildren: Bool) {
		let item = (item == rootSidebarItem) ? nil : item
		
		outlineView.reloadItem(item, reloadChildren: reloadChildren)
	}
	
	func isSelected(for item: OutlineItem) -> Bool {
		if item.isRoot {
			return false
		}
		
		let row = outlineView.row(forItem: item)
		return outlineView.isRowSelected(row)
	}
	
	func canDraggable(_ item: OutlineItem) -> Bool {
		if item.isRoot || item is OutlineGroupSectionItem {
			return false
		}
		
		return true
	}
	
	func item(at row: Int) -> OutlineItem? {
		outlineView.item(atRow: row) as? OutlineItem
	}
	
	func expandItem(_ item: OutlineItem, expandChildren: Bool) {
		outlineView.expandItem(item, expandChildren: expandChildren)
	}
	
	func collapseItem(_ item: OutlineItem) {
		outlineView.collapseItem(item)
	}
	
	func selectItems(_ items: [OutlineItem], byExtendingSelection: Bool) {
		let indexes = items.map { outlineView.row(forItem: $0) }
		let indexSet = IndexSet(indexes)
		outlineView.selectRowIndexes(indexSet, byExtendingSelection: byExtendingSelection)
	}
	
	func deselectItem(_ item: OutlineItem) {
		let row = outlineView.row(forItem: item)
		outlineView.deselectRow(row)
	}
	
	func resetExpansion(from itemStateInfo: [ItemStateInfo]) {
		for info in itemStateInfo.reversed() {
			if info.item.isRoot { continue }
			
			if info.isExpanded {
				expandItem(info.item, expandChildren: true)
			}
			else {
				collapseItem(info.item)
			}
		}
	}
	
	func resetSelection(from itemStateInfo: [ItemStateInfo]) {
		for info in itemStateInfo.reversed() {
			if info.item.isRoot { continue }
			
			if info.isSelected {
				selectItems([info.item], byExtendingSelection: true)
			}
			else {
				deselectItem(info.item)
			}
		}
	}
	
	
	// MARK: - DataSource – Basic
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if item == nil {
			return rootSidebarItem.children.count
		}
		
		return (item as? OutlineItem)?.children.count ?? 0
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		guard let item = item as? OutlineItem else {
			return rootSidebarItem.children[index]
		}
		
		return item.children[index]
	}
	
	func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
		guard let item = item as? OutlineItem else { return nil }
		
		if item is OutlineSeparatorItem {
			let rowViewIdentifier = item.rowViewIdentifier() ?? NSUserInterfaceItemIdentifier(CellIdentifier.separatorRow.rawValue)
			let rowView = outlineView.makeView(withIdentifier: rowViewIdentifier, owner: self) as? SeparatorRowView
			rowView?.identifier = rowViewIdentifier
			return rowView
		}
		
		let rowViewIdentifier = item.rowViewIdentifier() ?? NSUserInterfaceItemIdentifier(CellIdentifier.standardRow.rawValue)
		let rowView = OutlineRowView()
		rowView.identifier = rowViewIdentifier
		
		return rowView
	}
	
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		guard let item = item as? OutlineItem
		else { return nil }
		
		let cellViewIdentifier = item.cellViewType(for: tableColumn)
		
		if item is OutlineSeparatorItem {
			let cellView = NSTableCellView()
			cellView.identifier = cellViewIdentifier
			return cellView
		}
		
		var columnItem: OutlineColumnItem? = nil
		var columnIndex = 0
		if let tableColumn, let index = outlineView.tableColumns.firstIndex(of: tableColumn), item.columnItems.count > index {
			columnIndex = index
			columnItem = item.columnItems[index]
		}
		
		if let cellViewIdentifier, let cellView = outlineView.makeView(withIdentifier: cellViewIdentifier, owner: self) as? OutlineCellView {
			cellView.prepareForReuse()
			cellView.identifier = cellViewIdentifier
			cellView.objectValue = columnItem
			
			if columnIndex > 0 {
				cellView.setSecondaryAppearance()
			}
			else {
				cellView.setDefaultAppearance()
			}
			
			cellView.updateAppearance(window: outlineView.window)
			return cellView
		}
		
		return nil
	}
	
	
	// MARK: - Expandable / Group
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		if let item = item as? OutlineItem {
			if item.children.isEmpty {
				return item.isExpandableWhenEmpty
			}
			
			return item.isExpandable
		}
		
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		(item as? OutlineItem)?.isGroup ?? false
	}
	
	func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
		proposedSelectionIndexes.filteredIndexSet {
			guard let item = item(at: $0) else { return false }
			return item.isSelectable
		}
	}
	
	
	// MARK: - Display
	
//	/// Tintをカスタマイズ
//	func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
//		.init(preferredColor: .controlAccentColor)
//	}
	
	
	// MARK: - Selection
	
	func outlineViewSelectionDidChange(_ notification: Notification) {
		if notification.object as? NSOutlineView == outlineView {
			//let items = selectedItems()
			// TODO: do something
		}
	}
	
	
	// MARK: - Drag & Drop Support
	
	func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		// ドラッグ開始許可
		guard let item = item as? OutlineItem, canDraggable(item)
		else { return nil }
		return NSPasteboardItem(pasteboardPropertyList: item.itemIdentifier.uuidString, ofType: .sidebarItemDraggingType)
	}
	
	/// ドラッグ開始
	func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
		draggingItemInfo = nil
		
		// キャンセル時（escとか）に開始地点まで戻っていくアニメーションを無効にするか
		session.animatesToStartingPositionsOnCancelOrFail = false
		
		guard var draggedItems = draggedItems as? [OutlineItem]
		else { return }
		
		// セルの縦方向位置関係でソート（見かけの順番にする）
		draggedItems = draggedItems.sorted(by: { item1, item2 in
			let item1Frame = outlineView.frameOfOutlineCell(atRow: outlineView.row(forItem: item1))
			let item2Frame = outlineView.frameOfOutlineCell(atRow: outlineView.row(forItem: item2))
			return item1Frame.minY < item2Frame.minY
		})
		
		var draggingItemInfo = DraggingItemInfo(insertionIndex: 0)
		
		for draggedItem in draggedItems {
			let selectedFlag = true//isSelected(for: draggedItem)
			let expandedFlag = outlineView.isItemExpanded(draggedItem)
			let parentObject = outlineView.parent(forItem: draggedItem) as? OutlineItem ?? rootSidebarItem
			let index = outlineView.childIndex(forItem: draggedItem)
			
			if canDraggable(draggedItem) {
				draggingItemInfo.addItem(draggedItem, parent: parentObject, index: index)
				
				if (draggedItem.isExpandable && !draggedItem.children.isEmpty) {
					itemStateInfo.append(.init(item: draggedItem,
											   isExpanded: expandedFlag,
											   isSelected: selectedFlag))
				}
			}
		}
		
		self.draggingItemInfo = draggingItemInfo
	}
	
	func prepareForDragging(_ outlineView: NSOutlineView, validateDrop draggingInfo: NSDraggingInfo, proposedItem parentItem: Any?, proposedChildIndex index: Int) {
		// ドロップ表示のスタイル
		//outlineView.draggingDestinationFeedbackStyle = .regular // インジケータ表示スタイル
		//outlineView.draggingDestinationFeedbackStyle = .gap // Source List用
		outlineView.draggingDestinationFeedbackStyle = .sourceList // Source List用
		
		// ドロップ時アニメーション（使い方がわからない）
		draggingInfo.animatesToDestination = false
		//draggingInfo.animatesToDestination = true
		
		// ドラッグ中の表示形態
		draggingInfo.draggingFormation = .list // リスト
		//draggingInfo.draggingFormation = .stack // 積み重ね
		//draggingInfo.draggingFormation = .pile // ランダムに角度がついて重なる
	}
	
	/// ドラッグ最中
	func outlineView(_ outlineView: NSOutlineView, validateDrop draggingInfo: NSDraggingInfo, proposedItem parentItem: Any?, proposedChildIndex index: Int) -> NSDragOperation {
		// ドロップインジケータの制御: `.move`返却で表示、NSDragOperation()返却で非表示
		
		prepareForDragging(outlineView, validateDrop: draggingInfo, proposedItem: parentItem, proposedChildIndex: index)
		
		let parentItem = (parentItem as? OutlineItem) ?? rootSidebarItem
		let undroppable = NSDragOperation()
		
		
		print(#function, "\(index) root: \(parentItem.isRoot)")
		
		if draggingItemInfo?.itemInfo.isEmpty ?? true {
			return undroppable
		}
		
		if index == NSOutlineViewDropOnItemIndex {
			return undroppable
		}
		
		// セパレータへのドロップは無効
		if parentItem is OutlineSeparatorItem {
			return undroppable
		}
		
		// ドロップ候補先が非ルートで、開閉可能ではない場合は無効
		if !parentItem.isExpandable && parentItem.isRoot == false {
			return undroppable
		}
		
		// ドロップ候補先が現在掴んでいるアイテム群またはその子孫に含まれている場合は無効
		for itemInfo in (draggingItemInfo?.items() ?? []) {
			if itemInfo == parentItem || itemInfo.containsInTree(parentItem) {
				return undroppable
			}
		}
		
		// ドロップ候補先が現在掴んでいるアイテム群内の連続したセルの間である場合は無効
		// (NSOutlineViewDropOnItemIndex == -1)
		if index != NSOutlineViewDropOnItemIndex {
			let itemInfoArray = (draggingItemInfo?.itemInfo ?? [])
			var prevItemInfo: ItemInfo?
			
			for itemInfo in itemInfoArray {
				if let prevItemInfo {
					let i0 = prevItemInfo.index
					let i1 = itemInfo.index
					let isContinuous = (abs(i0 - i1) == 1) && (prevItemInfo.parent == itemInfo.parent)
					draggingItemInfo?.isContinuous[itemInfo.item.itemIdentifier] = isContinuous
				}
				
				prevItemInfo = itemInfo
			}
			
			if parentItem.children.count > index {
				let index = max(index, 0)
				let item = parentItem.children[index]
				if draggingItemInfo?.isContinuous[item.itemIdentifier] == true {
					return undroppable
				}
			}
		}
		
		return .move
	}
	
	/// ドロップ受け入れ
	func outlineView(_ outlineView: NSOutlineView, acceptDrop draggingInfo: NSDraggingInfo, item: Any?, childIndex toIndex: Int) -> Bool {
		let draggingItem = (item as? OutlineItem) ?? rootSidebarItem
		
		// セパレータのドラッグ禁止
		if draggingItem is OutlineSeparatorItem {
			return false
		}
		
		let to: Int
		switch toIndex {
			case NSOutlineViewDropOnItemIndex:
				to = draggingItem.children.count
			case -2:
				to = 0
			default:
				to = toIndex
		}
		
		let isSelected = isSelected(for: draggingItem)
		itemStateInfo.append(ItemStateInfo(item: draggingItem,
										   isExpanded: true,
										   isSelected: isSelected))
		
		draggingItemInfo?.newParent = draggingItem
		draggingItemInfo?.insertionIndex = to
		
		print(#function, "to: \(to) count: \(draggingItem.children.count)")
		
		if let draggingItemInfo {
			updateDataSource(draggingItemInfo)
			
			// リロード：カスタムアニメーションあり
			NSAnimationContext.runAnimationGroup { ctx in
				ctx.duration = CATransaction.animationDuration() + 0.2
				//ctx.duration = CATransaction.animationDuration() + 1.2
				
				ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1, 0.36, 1) // easeOutQuint
				//ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.68, -0.6, 0.32, 1.6) // easeInOutBack
				//ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.36, 0, 0.66, -0.56) // easeInBack
				//ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1) // easeOutBack
				self.reload(with: draggingItemInfo)
				
			} completionHandler: {
				self.reloadItem(nil, reloadChildren: true)
				self.resetExpansion(from: self.itemStateInfo)
				self.resetSelection(from: self.itemStateInfo)
				self.itemStateInfo.removeAll()
			}
			
			// リロード：アニメーションなし
//			reloadItem(nil, reloadChildren: true)
//			resetExpansion(from: itemStateInfo)
//			resetSelection(from: itemStateInfo)
//			itemStateInfo.removeAll()
			
			// 並び順情報
			if let sidebarOrder {
				let orderInfoArrayOfDraggingItems = draggingItemInfo.itemInfo.compactMap { itemInfo in
					itemInfo.item.orderInfo
				}
				
				// 並び順を保存
				sidebarOrder.move(elements: orderInfoArrayOfDraggingItems,
								  newIndex: to,
								  in: draggingItem.orderInfo)
				sidebarOrder.save()
				
#if DEBUG
				draggingItem.printChildrenInfo()
#endif
			}
		}
		
		return true
	}
	
	/// ドラッグ終了
	func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
		defer {
			// ドラッグ中のアイテムを解放
			self.draggingItemInfo = nil
		}
		
		if operation != .move {
			itemStateInfo.removeAll()
			return
		}
	}
	
}
