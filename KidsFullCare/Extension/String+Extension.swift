//
//  String+Extension.swift
//  KidsFullCare
//
//  Created by najak on 9/18/26.
//

import Foundation

extension String {
    func toDate(_ dateFormat: String = "yyyy-MM-dd") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
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
    
    var cleanAddress: String {
        var s = self.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
        // 동/호 제거 (예: 101동 1203호)
        s = s.replacingOccurrences(of: "\\s*\\d+동\\s*\\d+호.*$", with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }
}
