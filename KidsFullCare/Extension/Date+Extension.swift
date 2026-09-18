//
//  Date+Extension.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import Foundation

extension Date {
    
    static func isExpired(date: Date, timeInterval: Double) -> Bool {
        let thresoldDate = date.addingTimeInterval(timeInterval)
        return thresoldDate < Date()
    }
    
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
    
    var startOfToday: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self)
    }
    
    var endOfToday: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: self)!
    }
    
    public func dateCompare(fromDate: Date) -> String {
        let dateFormatter: DateFormatter = .init()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let fromDateString: String = dateFormatter.string(from: fromDate)
        let selfDateString: String = dateFormatter.string(from: self)
        
        if fromDateString == selfDateString {
            return "S"      // 동일
        } else if fromDateString > selfDateString {
            return "F"      // 미래
        } else if fromDateString < selfDateString {
            return "P"      // 과거
        }

        return ""
    }
    
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        
        return range.compactMap { day -> Date in
            calendar.date(byAdding: .day, value: day - 1, to: startDate) ?? Date()
        }
    }
    
    var startOfToMonth: Date {                  // 년/월에서 1일의 Date 찾기
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = Calendar.current.component(.month, from: self)
        components.day = 1
        return calendar.date(from: components)!
    }
    
    var endOfToMonth: Date {                    // 년/월에서 마지막 날짜의 Date 찾기
        let startDate = self.startOfToMonth
        let endDayInterval = startDate.getAllDates().count
        let endDate = Calendar.current.date(byAdding: .day, value: endDayInterval - 1, to: startDate)!
        return endDate
    }
    
    var startofToYear: Date {                   // 년도의 1월 1일 Date 찾기
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = 1
        components.day = 1
        return calendar.date(from: components)!
    }
    
    var endofToYear: Date {                     // 년도의 12월 31일의 Date 찾기
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: self)
        components.month = 12
        components.day = 31
        return calendar.date(from: components)!
    }
}
