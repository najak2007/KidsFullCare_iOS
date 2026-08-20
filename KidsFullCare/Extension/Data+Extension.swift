//
//  Data+Extension.swift
//  KidsFullCare
//
//  Created by najak on 8/20/26.
//

import Foundation

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
