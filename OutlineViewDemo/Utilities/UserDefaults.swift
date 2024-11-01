//
//  UserDefaults.swift
//
//  Created by usagimaru on 2024/03/02.
//  Copyright © 2024 usagimaru.
//

import Foundation

extension UserDefaults {
	
	func saveCodableObject(_ value: Codable?, forKey key: String) {
		guard let json: Any = value?.json
		else { return }
		self.set(json, forKey: key)
		synchronize()
	}
	
	func loadCodableObject<T: Codable>(forKey key: String) -> T? {
		let data = self.data(forKey: key)
		let object = T.decode(json: data)
		return object
	}
	
}

extension Encodable {
	
	var json: Data? {
		let encoder = JSONEncoder()
		return try? encoder.encode(self)
	}
	
}

extension Decodable {
	
	static func decode(json data: Data?) -> Self? {
		guard let data = data else { return nil }
		let decoder = JSONDecoder()
		return try? decoder.decode(Self.self, from: data)
	}
	
}

