//
//  Array.swift
//
//  Copyright © 2019 usagimaru. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
	
	/// 重複を除外
	var uniques: Array {
		var buffer = Array()
		var added = Set<Element>()
		for elem in self {
			if !added.contains(elem) {
				buffer.append(elem)
				added.insert(elem)
			}
		}
		return buffer
	}
	
	mutating func unique() {
		var buffer = Array()
		var added = Set<Element>()
		for elem in self {
			if !added.contains(elem) {
				buffer.append(elem)
				added.insert(elem)
			}
		}
		
		self = buffer
	}
	
	/// 指定オブジェクトを削除
	mutating func remove(_ object: Element) {
		while self.contains(object) {
			if let i = self.firstIndex(of: object) {
				self.remove(at: i)
			}
		}
	}
	
	mutating func removeAll(of object: Element, handler: (_ object: Element) -> Bool) {
		var index = -1
		while self.contains(object) {
			index = self.index(after: index)
			
			if handler(object) && self.count > index {
				self.remove(at: index)
			}
		}
	}
	
	mutating func removeAll(of object: Element) {
		var index = -1
		while self.contains(object) {
			index = self.index(after: index)
			
			if self.count > index {
				self.remove(at: index)
			}
		}
	}
	
	/// クロージャで評価した結果によって該当オブジェクトを削除
	mutating func removeObjects(where evaluation: (_ target: Element) -> Bool) {
		var indexes = [Int]()
		for (i, element) in self.enumerated() {
			if evaluation(element) {
				indexes.append(i)
			}
		}
		
		while indexes.count > 0 {
			guard let i = indexes.last else { break }
			self.remove(at: i)
			indexes.removeLast()
		}
	}
	
}
