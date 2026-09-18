//
//  String+Extension.swift
//  KidsFullCare
//
//  Created by najak on 9/18/26.
//

import Foundation

extension String {
    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return nil
        }
    }
    
    var isNumber: Bool {
        if Int(self) != nil || Double(self) != nil {
            return true
        }
        return false
    }
    
    var lastString: String? {
        let str = self
        let lastIndex = str.index(before: endIndex)
        return  String(str[lastIndex...])
    }
    
    var firstString: String? {
        let str = self
        let firstIndex = str.index(after: startIndex)
        return String(str[..<firstIndex])
    }
    
    var zeroAdded: String {
        if self.count == 1 {
            return self
        } else if self.count > 1 {
            if self.lastString == "." {
                return self + "0"
            } else if self.firstString == "." {
                return "0" + self
            }
        }
        return self
    }
    
    var toAddComma: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        if let number = numberFormatter.number(from: self) {
            return numberFormatter.string(from: number) ?? self
        }
        return self
    }
}
