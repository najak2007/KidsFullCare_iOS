//
//  Decodable+Extension.swift
//  KidsFullCare
//
//  Created by najak on 9/4/26.
//

import Foundation

extension Decodable {
    static func decode<T: Decodable>(dictionary: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.fragmentsAllowed])
        return try JSONDecoder().decode(T.self, from: data)
    }
}
