//
//  OutlineItem.swift
//
//  Created by usagimaru on 2021/09/07.
//

import Cocoa

enum CellIdentifier: String {
	case standardCell
	case standardRow
	case sectionHeader
	case separatorRow
}

class OutlineItem: NSObject, ListOrderSupport {
	
	typealias ItemID = UUID
	
	/// 固有番号
	var itemIdentifier: ItemID = ItemID()
	
	/// グループか
	var isGroup: Bool {
		get {
			isRoot ? false : _isGroup
		}
		set {
			_isGroup = newValue
		}
	}
	private var _isGroup: Bool = false
	
	/// 開閉可能か
	var isExpandable: Bool {
		get {
			isRoot ? false : _isExpandable
		}
		set {
			_isExpandable = newValue
		}
	}
	private var _isExpandable: Bool = false
	
	/// 空の際に開閉可能か
	var isExpandableWhenEmpty: Bool {
		get {
			isRoot ? false : _isExpandableWhenEmpty
		}
		set {
			_isExpandableWhenEmpty = newValue
		}
	}
	private var _isExpandableWhenEmpty: Bool = false
	
	/// 選択可能か
	var isSelectable: Bool {
		get {
			isRoot ? false : _isSelectable
		}
		set {
			_isSelectable = newValue
		}
	}
	private var _isSelectable: Bool = true
	
	/// 親アイテム
	weak var parent: OutlineItem?
	
	/// 子アイテム
	private(set) var children = [OutlineItem]()
	
	/// 列アイテム
	var columnItems = [OutlineColumnItem]()
	
	/// ルートか
	var isRoot: Bool {
		parent == nil
	}
	
	/// 並び順情報
	var orderInfo: String {
		get {
			self.isRoot ? Self.rootOrderInfo : _orderInfo
		}
		set {
			if !self.isRoot {
				_orderInfo = newValue
			}
		}
	}
	private var _orderInfo: String = ""
	static let rootOrderInfo = "root"
	
	
	// MARK: -
	
	override init() {
		super.init()
	}
	
	convenience init(_ builder: (() -> [OutlineItem])? = nil, title: String? = nil, image: NSImage? = nil) {
		self.init()
		self.columnItems.append(OutlineColumnItem(title: title, image: image))
		append(builder?() ?? []) // parent設定をするために、append()を通す
	}
	
	convenience init(_ builder: (() -> [OutlineItem])? = nil, columnItems: [OutlineColumnItem]) {
		self.init()
		self.columnItems = columnItems
		append(builder?() ?? []) // parent設定をするために、append()を通す
	}
	
	/// NSTableCellView IDを返す
	func cellViewType(for tableColumn: NSTableColumn?) -> NSUserInterfaceItemIdentifier? {
		NSUserInterfaceItemIdentifier(CellIdentifier.standardCell.rawValue)
	}
	
	/// NSTableRowView IDを返す
	func rowViewIdentifier() -> NSUserInterfaceItemIdentifier? {
		nil
	}
	
	override var hash: Int {
		itemIdentifier.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		guard let item = object as? OutlineItem else { return false }
		return item.itemIdentifier == itemIdentifier
	}
	
	func moveChild(_ childItem: OutlineItem, to: Int) {
		if children[to] == childItem { return }
		if !children.contains(childItem) { return }
		guard let oldIndex = children.firstIndex(of: childItem) else {
			return
		}
		
		if oldIndex < to {
			children.remove(childItem)
			children.insert(childItem, at: to - 1)
		}
		else {
			children.remove(childItem)
			children.insert(childItem, at: to)
		}
	}
	
	func insertOrMoveChildren(_ insertedChildren: [OutlineItem], to: Int?) {
		// childrenに含まれるアイテムのみ抽出
		let localChildren = insertedChildren.filter {
			children.contains($0)
		}
		
		// indexズレを防ぐため、プレースホルダで一旦置き換える
		var placeholders = [OutlinePlaceholderItem]()
		localChildren.forEach { localChild in
			if let index = children.firstIndex(of: localChild) {
				let placeholder = OutlinePlaceholderItem(parent: self)
				placeholders.append(placeholder)
				children[index] = placeholder
			}
		}
		
		if let to, to < children.count {
			children.insert(contentsOf: insertedChildren, at: to)
		}
		else {
			children.append(contentsOf: insertedChildren)
		}
		
		insertedChildren.forEach {
			$0.parent = self
		}
		
		// プレースホルダを取り除く
		placeholders.forEach {
			children.remove($0)
		}
	}
	
	func append(_ items: [OutlineItem]) {
		children.append(contentsOf: items)
		items.forEach { $0.parent = self }
	}
	
	func removeFromParent() {
		parent?.children.remove(self)
		parent = nil
	}
	
	func remove(_ item: OutlineItem) {
		children.remove(item)
		item.parent = nil
	}
	
	func searchItem(_ itemIdentifier: ItemID) -> OutlineItem? {
		for child in children {
			if child.itemIdentifier == itemIdentifier {
				return child
			}
			
			let result = child.searchItem(itemIdentifier)
			if result != nil {
				return result
			}
		}
		
		return nil
	}
	
	/// 子孫 children に item が含まれるか
	func containsInTree(_ item: OutlineItem) -> Bool {
		if children.contains(item) {
			return true
		}
		
		for child in children {
			if child.containsInTree(item) {
				return true
			}
		}
		
		return false
	}
	
	/// 先祖 parent のいずれかが item と同等か
	func searchEquivalenceInParents(_ item: OutlineItem) -> Bool {
		if parent == item {
			return true
		}
		
		return parent?.searchEquivalenceInParents(item) ?? false
	}
	
	/// children を並び替える
	func sortChildren(by areInIncreasingOrder: @escaping (OutlineItem, OutlineItem) throws -> Bool) rethrows {
		try children.sort(by: areInIncreasingOrder)
	}
	
}

struct OutlineColumnItem {
	var title: String?
	var image: NSImage?
}

class OutlineFolderItem: OutlineItem {
	
	override var isGroup: Bool {
		get { false }
		set {}
	}
	override var isExpandable: Bool {
		get { true }
		set {}
	}
	override var isExpandableWhenEmpty: Bool {
		get { true }
		set {}
	}
	
}

class OutlineGroupSectionItem: OutlineItem {
	
	override var isGroup: Bool {
		get { true }
		set {}
	}
	override var isExpandable: Bool {
		get { true }
		set {}
	}
	override var isExpandableWhenEmpty: Bool {
		get { true }
		set {}
	}
	override var isSelectable: Bool {
		get { false }
		set {}
	}
	
}

class OutlinePlaceholderItem: OutlineItem {
	
	override var isGroup: Bool {
		get { false }
		set {}
	}
	override var isExpandable: Bool {
		get { false }
		set {}
	}
	override var isExpandableWhenEmpty: Bool {
		get { false }
		set {}
	}
	override var isSelectable: Bool {
		get { false }
		set {}
	}
	override var isRoot: Bool {
		false
	}
	
	convenience init(parent: OutlineItem? = nil) {
		self.init()
		self.parent = parent
	}
	
}

class OutlineSeparatorItem: OutlineItem {
	
	override var isGroup: Bool {
		get { false }
		set {}
	}
	override var isExpandable: Bool {
		get { false }
		set {}
	}
	override var isExpandableWhenEmpty: Bool {
		get { false }
		set {}
	}
	override var isSelectable: Bool {
		get { false }
		set {}
	}
	override var isRoot: Bool {
		false
	}
	
	override var children: [OutlineItem] {
		get { return [] }
		set {}
	}
	
	override func rowViewIdentifier() -> NSUserInterfaceItemIdentifier? {
		NSUserInterfaceItemIdentifier(CellIdentifier.separatorRow.rawValue)
	}
	
}


// MARK: -

protocol ListOrderSupport: OutlineItem {
	
	var orderInfo: String { get set }
	
}

extension ListOrderSupport {
	
	/// 現状のアイテムツリー構造から並び順情報を作る
	func newOrder() -> OutlineOrder {
		let order = OutlineOrder()
		updateOutlineOrder(into: order)
		return order
	}
	
	/// 現状のアイテムツリー構造から並び順情報を作り、既存の OutlineOrder オブジェクトを更新する
	func updateOutlineOrder(into order: OutlineOrder) {
		children.forEach {
			// 必要なら空配列を追加
			order.registerEmptyArray(with: orderInfo)
			
			// 並び順情報を登録
			order.add(element: $0.orderInfo, in: orderInfo)
			$0.updateOutlineOrder(into: order)
		}
	}
	
	///　children を並び替える (ListOrderSupport対応版)
	func sortChildren(by areInIncreasingOrder: @escaping (OutlineItem, OutlineItem) throws -> Bool) rethrows {
		try sortChildren { item1, item2 in
			return try areInIncreasingOrder(item1, item2)
		}
	}
	
	/// アイテムツリー構造の並び順を設定
	func reflectOrdersToItemTree(_ order: OutlineOrder) {
		if let childrenOrder = order.orderedList(for: orderInfo) {
			sortChildren { item1, item2 in
				let i1 = childrenOrder.firstIndex(of: item1.orderInfo) ?? Int.max
				let i2 = childrenOrder.firstIndex(of: item2.orderInfo) ?? Int.max
				return i1 < i2
			}
		}
		
		children.forEach { childItem in
			childItem.reflectOrdersToItemTree(order)
		}
	}
	
	/// デバッグ用
	func printChildrenInfo() {
		if !children.isEmpty {
			print(#function, "Children’s orderInfo:")
		}
		for (i, item) in children.enumerated() {
			item.columnItems.forEach { columnItem in
				print("\t#\(i): \(columnItem.title ?? "")\n\t\t\(item.orderInfo)")
			}
		}
	}
	
}
