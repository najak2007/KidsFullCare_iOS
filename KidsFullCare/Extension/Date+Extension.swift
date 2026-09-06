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
    
    func getMessageID() -> String {
        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSSSSS"
        let newID: String = dateFormatter.string(from: date)
        return newID
    }
    
    func findCurrentYearInterval() -> Int {
        guard let startDate = Config.APP_START_DATE
        else {
            return 0
        }
        
        let components = Calendar.current.dateComponents([.year], from: startDate, to: self)
        
        guard let yearInt = components.year
        else {
            return 0
        }
        return yearInt == 0 ? 1 : yearInt
    }
    
    func timeSecondInterval(end: Date) -> Int {
        let components = Calendar.current.dateComponents([.second], from: self, to: end)
        guard let secondInt = components.second else { return 0 }
        return secondInt
    }
    
    func timeMinuteInterval(end: Date) -> Double {
        let components = Calendar.current.dateComponents([.minute], from: self, to: end)
        guard let minuteInt = components.minute else { return 0 }
        return Double(minuteInt)
    }
}
