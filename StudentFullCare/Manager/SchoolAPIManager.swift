//
//  SchoolAPIManager.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import Foundation

class SchoolAPIManager: NSObject {
    static func fetchSchedult(for: Date) -> ScheduleInfo {
        return ScheduleInfo(schedule: .today, isActive: true)
    }
}
