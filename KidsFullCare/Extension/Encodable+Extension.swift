//
//  Encodable+Extension.swift
//  KidsFullCare
//
//  Created by najak on 9/20/26.
//

import Foundation

extension Encodable {
    func toDictionary(encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoder.encode(self)
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])

        guard let dictionary = object as? [String: Any] else {
            throw EncodingError.invalidValue(
                self,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "최상위 값이 Dictionary가 아닙니다."
                )
            )
        }
        return dictionary
    }
}
