//
//  ScheduleInfo.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import Foundation

struct ScheduleInfo: Codable, Hashable {
    var id: String = UUID().uuidString
    let schedule: Date
    let isActive: Bool
    let isEmpty: Bool
}
