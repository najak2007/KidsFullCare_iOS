//
//  Date+Extension.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import Foundation

extension Date {
    static var today: Date {
        return Date()
    }
    
    func getDataID() -> String {
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let newID: String = dateFormatter.string(from: date)
        return newID
    }
}
