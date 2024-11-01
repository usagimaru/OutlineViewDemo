//
//  OutlineOrder.swift
//
//  Created by usagimaru on 2024/09/11.
//

import Cocoa

class OutlineOrder: Codable {
	
	typealias ElementID = String
	typealias OrderArray = [ElementID : [ElementID]]
	
	enum CodingKeys: CodingKey {
		case orderArray
	}
	
	var orderArray: OrderArray
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.orderArray = try container.decode(OrderArray.self, forKey: .orderArray)
	}
	
	init(with orderArray: OrderArray = .init()) {
		self.orderArray = orderArray
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.orderArray, forKey: .orderArray)
	}
	
	func registerEmptyArray(with id: ElementID, ifExistingIsNil: Bool = true) {
		if (ifExistingIsNil == true && orderArray[id] == nil) || ifExistingIsNil == false {
			orderArray[id] = []
		}
	}
	
	func register(list: [ElementID] = [], id: ElementID) {
		orderArray[id] = list
	}
	
	func add(element id: ElementID, in: ElementID) {
		if var list = orderArray[`in`], list.contains(where: { $0 == id }) == false {
			list.append(id)
			orderArray[`in`] = list
		}
	}
	
	func insert(elements ids: [ElementID], at: Int, in: ElementID) {
		if var list = orderArray[`in`], 0..<list.count ~= at {
			let ids = ids.filter { id in
				list.contains { id != $0 }
			}
			list.insert(contentsOf: ids, at: at)
			orderArray[`in`] = list
		}
	}
	
	func insert(elements ids: [ElementID], before: ElementID, in: ElementID) {
		if var list = orderArray[`in`], let targetIndex = list.firstIndex(of: before) {
			let ids = ids.filter { id in
				list.contains { id != $0 } && id != before
			}
			list.insert(contentsOf: ids, at: targetIndex)
			orderArray[`in`] = list
		}
	}
	
	func insert(elements ids: [ElementID], after: ElementID, in: ElementID) {
		if var list = orderArray[`in`], let targetIndex = list.firstIndex(of: after), targetIndex + 1 < list.count {
			let ids = ids.filter { id in
				list.contains { id != $0 } && id != after
			}
			list.insert(contentsOf: ids, at: targetIndex + 1)
			orderArray[`in`] = list
		}
	}
	
	func move(elements ids: [ElementID], newIndex: Int, in: ElementID) {
		if var list = orderArray[`in`], 0..<list.count ~= newIndex {
			let indexes = ids.compactMap {
				list.firstIndex(of: $0)
			}
			let indexSet = IndexSet(indexes)
			list.move(fromOffsets: indexSet, toOffset: newIndex)
			orderArray[`in`] = list
		}
	}
	
	func move(elements ids: [ElementID], before: ElementID, in: ElementID) {
		if var list = orderArray[`in`], let targetIndex = list.firstIndex(of: before) {
			let indexes = ids.compactMap {
				list.firstIndex(of: $0)
			}
			list.move(fromOffsets: IndexSet(indexes), toOffset: targetIndex)
			orderArray[`in`] = list
		}
	}
	
	func move(elements ids: [ElementID], after: ElementID, in: ElementID) {
		if var list = orderArray[`in`], let targetIndex = list.firstIndex(of: after), targetIndex + 1 < list.count {
			let indexes = ids.compactMap {
				list.firstIndex(of: $0)
			}
			list.move(fromOffsets: IndexSet(indexes), toOffset: targetIndex + 1)
			orderArray[`in`] = list
		}
	}
	
	func remove(element at: Int, in: ElementID) {
		if var list = orderArray[`in`], 0..<list.count ~= at {
			list.remove(at: at)
			orderArray[`in`] = list
		}
	}
	
	func remove(element id: ElementID, in: ElementID) {
		orderArray[`in`]?.remove(id)
	}
	
	func orderedList(for id: ElementID) -> [ElementID]? {
		orderArray[id]
	}
	
	
	// MARK: -
	
	static let userDefaultsKey = "OutlineOrderArray"
	
	func save() {
		UserDefaults.standard.saveCodableObject(self, forKey: OutlineOrder.userDefaultsKey)
	}
	
	static func load() -> Self? {
		UserDefaults.standard.loadCodableObject(forKey: OutlineOrder.userDefaultsKey)
	}
	
}
